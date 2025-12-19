//
//  FirebaseService.swift
//  EnPlace2
//
//  Created for EnPlace - Household recipe matching
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - User Model

struct EnPlaceUser: Codable {
    let id: String
    let email: String
    var displayName: String
    var householdId: String?
    var isChefA: Bool  // true = created household, false = joined household
    let createdAt: Date
}

// MARK: - Household Model

struct Household: Codable, Equatable {
    let id: String
    let inviteCode: String
    var chefAId: String
    var chefBId: String?
    var chefALikes: [String]  // Recipe names
    var chefBLikes: [String]  // Recipe names
    var matches: [String]     // Recipe names both chefs liked
    var mealPlan: [String: [String]]  // Day -> Recipe names
    let createdAt: Date
    
    // Custom decoder to handle existing households without mealPlan field
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        inviteCode = try container.decode(String.self, forKey: .inviteCode)
        chefAId = try container.decode(String.self, forKey: .chefAId)
        chefBId = try container.decodeIfPresent(String.self, forKey: .chefBId)
        chefALikes = try container.decode([String].self, forKey: .chefALikes)
        chefBLikes = try container.decode([String].self, forKey: .chefBLikes)
        matches = try container.decode([String].self, forKey: .matches)
        // Default to empty dict if mealPlan doesn't exist in Firebase
        mealPlan = try container.decodeIfPresent([String: [String]].self, forKey: .mealPlan) ?? [:]
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    // Standard initializer for creating new households
    init(id: String, inviteCode: String, chefAId: String, chefBId: String?, chefALikes: [String], chefBLikes: [String], matches: [String], mealPlan: [String: [String]], createdAt: Date) {
        self.id = id
        self.inviteCode = inviteCode
        self.chefAId = chefAId
        self.chefBId = chefBId
        self.chefALikes = chefALikes
        self.chefBLikes = chefBLikes
        self.matches = matches
        self.mealPlan = mealPlan
        self.createdAt = createdAt
    }
}

// MARK: - Firebase Service

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Published var currentUser: EnPlaceUser?
    @Published var currentHousehold: Household?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var householdListener: ListenerRegistration?
    
    private init() {
        // Listen for auth state changes
        auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.fetchUserData(userId: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.currentHousehold = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Authentication
    
    /// Sign up with email and password
    @MainActor
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Create user document in Firestore
            let newUser = EnPlaceUser(
                id: result.user.uid,
                email: email,
                displayName: displayName,
                householdId: nil,
                isChefA: false,
                createdAt: Date()
            )
            
            try await saveUser(newUser)
            currentUser = newUser
            isAuthenticated = true
            isLoading = false
            print("✅ User signed up: \(email)")
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Sign in with email and password
    @MainActor
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            await fetchUserData(userId: result.user.uid)
            isLoading = false
            print("✅ User signed in: \(email)")
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Sign out
    @MainActor
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        currentHousehold = nil
        isAuthenticated = false
        householdListener?.remove()
        print("✅ User signed out")
    }
    
    // MARK: - User Data
    
    @MainActor
    private func fetchUserData(userId: String) async {
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            if let data = doc.data() {
                currentUser = try Firestore.Decoder().decode(EnPlaceUser.self, from: data)
                isAuthenticated = true
                
                // If user has a household, listen to it
                if let householdId = currentUser?.householdId {
                    listenToHousehold(householdId: householdId)
                }
            }
        } catch {
            print("❌ Error fetching user: \(error)")
        }
    }
    
    private func saveUser(_ user: EnPlaceUser) async throws {
        let data = try Firestore.Encoder().encode(user)
        try await db.collection("users").document(user.id).setData(data)
    }
    
    // MARK: - Household Management
    
    /// Generate a random invite code (e.g., "PASTA-2847")
    private func generateInviteCode() -> String {
        let words = ["PASTA", "TACOS", "PIZZA", "CURRY", "SUSHI", "RAMEN", "SALAD", "STEAK", "TOAST", "CREPE"]
        let word = words.randomElement() ?? "MEAL"
        let number = String(format: "%04d", Int.random(in: 1000...9999))
        return "\(word)-\(number)"
    }
    
    /// Create a new household (Chef A)
    @MainActor
    func createHousehold() async throws -> String {
        guard var user = currentUser else {
            throw NSError(domain: "EnPlace", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }
        
        // If user already has a household, clean it up first
        if let existingHouseholdId = user.householdId {
            print("⚠️ User already has household \(existingHouseholdId), cleaning up...")
            try await cleanupOrphanedHousehold(householdId: existingHouseholdId, userId: user.id)
        }
        
        let inviteCode = generateInviteCode()
        let householdId = UUID().uuidString
        
        let household = Household(
            id: householdId,
            inviteCode: inviteCode,
            chefAId: user.id,
            chefBId: nil,
            chefALikes: [],
            chefBLikes: [],
            matches: [],
            mealPlan: [:],
            createdAt: Date()
        )
        
        // Save household
        let householdData = try Firestore.Encoder().encode(household)
        try await db.collection("households").document(householdId).setData(householdData)
        
        // Update user
        user.householdId = householdId
        user.isChefA = true
        try await saveUser(user)
        
        currentUser = user
        currentHousehold = household
        listenToHousehold(householdId: householdId)
        
        print("✅ Created household with code: \(inviteCode)")
        return inviteCode
    }
    
    /// Clean up an orphaned household (when user had old household reference)
    private func cleanupOrphanedHousehold(householdId: String, userId: String) async throws {
        // Remove listener if active
        householdListener?.remove()
        currentHousehold = nil
        
        // Try to fetch the household to see if it still exists
        let doc = try? await db.collection("households").document(householdId).getDocument()
        
        if let doc = doc, doc.exists {
            // Household exists - check if we should delete it or just remove ourselves
            if let data = doc.data(),
               let household = try? Firestore.Decoder().decode(Household.self, from: data) {
                
                // If we're Chef A and there's no Chef B, delete the whole household
                if household.chefAId == userId && household.chefBId == nil {
                    try await db.collection("households").document(householdId).delete()
                    print("🗑️ Deleted orphaned household \(householdId)")
                } else if household.chefAId == userId {
                    // We're Chef A but there's a Chef B - just remove ourselves
                    var updatedHousehold = household
                    updatedHousehold.chefAId = household.chefBId ?? ""
                    updatedHousehold.chefBId = nil
                    let data = try Firestore.Encoder().encode(updatedHousehold)
                    try await db.collection("households").document(householdId).setData(data)
                    print("🔄 Transferred household ownership to Chef B")
                } else if household.chefBId == userId {
                    // We're Chef B - just remove ourselves
                    var updatedHousehold = household
                    updatedHousehold.chefBId = nil
                    updatedHousehold.chefBLikes = []
                    // Recalculate matches
                    updatedHousehold.matches = []
                    let data = try Firestore.Encoder().encode(updatedHousehold)
                    try await db.collection("households").document(householdId).setData(data)
                    print("🔄 Removed self from household as Chef B")
                }
            }
        } else {
            print("ℹ️ Old household \(householdId) no longer exists")
        }
    }
    
    /// Join an existing household (Chef B)
    @MainActor
    func joinHousehold(inviteCode: String) async throws {
        guard var user = currentUser else {
            throw NSError(domain: "EnPlace", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }
        
        // If user already has a household, clean it up first
        if let existingHouseholdId = user.householdId {
            print("⚠️ User already has household \(existingHouseholdId), cleaning up...")
            try await cleanupOrphanedHousehold(householdId: existingHouseholdId, userId: user.id)
        }
        
        // Find household by invite code
        let query = db.collection("households").whereField("inviteCode", isEqualTo: inviteCode.uppercased())
        let snapshot = try await query.getDocuments()
        
        guard let doc = snapshot.documents.first else {
            throw NSError(domain: "EnPlace", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid invite code"])
        }
        
        var household = try Firestore.Decoder().decode(Household.self, from: doc.data())
        
        // Check if household already has Chef B
        if household.chefBId != nil {
            throw NSError(domain: "EnPlace", code: 3, userInfo: [NSLocalizedDescriptionKey: "This household already has two chefs"])
        }
        
        // Update household with Chef B
        household.chefBId = user.id
        let householdData = try Firestore.Encoder().encode(household)
        try await db.collection("households").document(household.id).setData(householdData)
        
        // Update user
        user.householdId = household.id
        user.isChefA = false
        try await saveUser(user)
        
        currentUser = user
        currentHousehold = household
        listenToHousehold(householdId: household.id)
        
        print("✅ Joined household: \(inviteCode)")
    }
    
    /// Leave current household
    @MainActor
    func leaveHousehold() async throws {
        guard var user = currentUser, let householdId = user.householdId else { return }
        
        // Remove listener
        householdListener?.remove()
        
        // Update user
        user.householdId = nil
        user.isChefA = false
        try await saveUser(user)
        
        currentUser = user
        currentHousehold = nil
        
        print("✅ Left household")
    }
    
    // MARK: - Real-time Household Listening
    
    private func listenToHousehold(householdId: String) {
        householdListener?.remove()
        
        householdListener = db.collection("households").document(householdId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let data = snapshot?.data() else { return }
                
                do {
                    let household = try Firestore.Decoder().decode(Household.self, from: data)
                    Task { @MainActor in
                        self?.currentHousehold = household
                    }
                } catch {
                    print("❌ Error decoding household: \(error)")
                }
            }
    }
    
    // MARK: - Swipe Management
    
    /// Record a like (swipe right) for a recipe
    func likeRecipe(recipeName: String) async throws {
        guard let user = currentUser,
              let householdId = user.householdId else { return }
        
        // Fetch the LATEST household data from Firebase to avoid stale data issues
        let doc = try await db.collection("households").document(householdId).getDocument()
        guard let data = doc.data() else { return }
        var household = try Firestore.Decoder().decode(Household.self, from: data)
        
        // Add to appropriate likes array
        if user.isChefA {
            if !household.chefALikes.contains(recipeName) {
                household.chefALikes.append(recipeName)
                print("👍 Chef A liked: \(recipeName)")
            }
        } else {
            if !household.chefBLikes.contains(recipeName) {
                household.chefBLikes.append(recipeName)
                print("👍 Chef B liked: \(recipeName)")
            }
        }
        
        // Check for new match (using fresh data!)
        if household.chefALikes.contains(recipeName) && household.chefBLikes.contains(recipeName) {
            if !household.matches.contains(recipeName) {
                household.matches.append(recipeName)
                print("🎉 NEW MATCH: \(recipeName)")
            }
        }
        
        // Save to Firestore
        let updatedData = try Firestore.Encoder().encode(household)
        try await db.collection("households").document(householdId).setData(updatedData)
    }
    
    /// Get matched recipe names
    var matchedRecipeNames: [String] {
        currentHousehold?.matches ?? []
    }
    
    /// Get current user's likes
    var myLikes: [String] {
        guard let user = currentUser, let household = currentHousehold else { return [] }
        return user.isChefA ? household.chefALikes : household.chefBLikes
    }
    
    /// Check if partner has joined
    var hasPartner: Bool {
        currentHousehold?.chefBId != nil
    }
    
    /// Get invite code for current household
    var inviteCode: String? {
        currentHousehold?.inviteCode
    }
    
    // MARK: - Meal Plan Management
    
    /// Get current meal plan
    var mealPlan: [String: [String]] {
        currentHousehold?.mealPlan ?? [:]
    }
    
    /// Add a recipe to a specific day
    func addRecipeToMealPlan(day: String, recipeName: String) async throws {
        guard let householdId = currentUser?.householdId,
              var household = currentHousehold else { return }
        
        // Initialize day array if needed
        if household.mealPlan[day] == nil {
            household.mealPlan[day] = []
        }
        
        // Add recipe if not already there
        if !household.mealPlan[day]!.contains(recipeName) {
            household.mealPlan[day]!.append(recipeName)
        }
        
        // Save to Firestore
        let data = try Firestore.Encoder().encode(household)
        try await db.collection("households").document(householdId).setData(data)
        print("📅 Added \(recipeName) to \(day)")
    }
    
    /// Remove a recipe from a specific day
    func removeRecipeFromMealPlan(day: String, recipeName: String) async throws {
        guard let householdId = currentUser?.householdId,
              var household = currentHousehold else { return }
        
        // Remove recipe from day
        household.mealPlan[day]?.removeAll { $0 == recipeName }
        
        // Clean up empty days
        if household.mealPlan[day]?.isEmpty == true {
            household.mealPlan.removeValue(forKey: day)
        }
        
        // Save to Firestore
        let data = try Firestore.Encoder().encode(household)
        try await db.collection("households").document(householdId).setData(data)
        print("📅 Removed \(recipeName) from \(day)")
    }
    
    /// Clear all meals for a specific day
    func clearMealsForDay(day: String) async throws {
        guard let householdId = currentUser?.householdId,
              var household = currentHousehold else { return }
        
        household.mealPlan.removeValue(forKey: day)
        
        let data = try Firestore.Encoder().encode(household)
        try await db.collection("households").document(householdId).setData(data)
        print("📅 Cleared meals for \(day)")
    }
    
    // MARK: - Recipe Management (Firestore-based)
    
    /// Fetch recipes with pagination and optional filters
    func fetchRecipes(
        limit: Int = 20,
        startAfter: DocumentSnapshot? = nil,
        cuisine: String? = nil,
        maxCookTime: Int? = nil,
        chefLevel: String? = nil,
        isForFamily: Bool? = nil
    ) async throws -> (recipes: [FirestoreRecipe], lastDocument: DocumentSnapshot?) {
        var query: Query = db.collection("recipes")
        
        // Apply filters (Firestore can only do equality + one inequality)
        if let cuisine = cuisine {
            query = query.whereField("cuisine", isEqualTo: cuisine)
        }
        
        if let isForFamily = isForFamily {
            query = query.whereField("isForFamily", isEqualTo: isForFamily)
        }
        
        if let chefLevel = chefLevel {
            query = query.whereField("chefLevel", isEqualTo: chefLevel)
        }
        
        // Order by name for consistent pagination
        query = query.order(by: "name")
        
        // Pagination
        if let startAfter = startAfter {
            query = query.start(afterDocument: startAfter)
        }
        
        query = query.limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        
        let recipes = snapshot.documents.compactMap { doc -> FirestoreRecipe? in
            try? doc.data(as: FirestoreRecipe.self)
        }
        
        // Client-side filter for cook time (Firestore limitation with multiple inequalities)
        var filteredRecipes = recipes
        if let maxCookTime = maxCookTime {
            filteredRecipes = recipes.filter { $0.cookTimeMinutes <= maxCookTime }
        }
        
        let lastDoc = snapshot.documents.last
        print("📚 Fetched \(filteredRecipes.count) recipes from Firestore")
        
        return (filteredRecipes, lastDoc)
    }
    
    /// Upload a single recipe to Firestore
    func uploadRecipe(_ recipe: FirestoreRecipe) async throws {
        let docRef = db.collection("recipes").document(recipe.id)
        try docRef.setData(from: recipe)
        print("✅ Uploaded recipe: \(recipe.name)")
    }
    
    /// Batch upload recipes to Firestore (for migration)
    func uploadRecipesBatch(_ recipes: [FirestoreRecipe]) async throws {
        let batch = db.batch()
        
        for recipe in recipes {
            let docRef = db.collection("recipes").document(recipe.id)
            try batch.setData(from: recipe, forDocument: docRef)
        }
        
        try await batch.commit()
        print("✅ Uploaded batch of \(recipes.count) recipes")
    }
    
    /// Get total recipe count
    func getRecipeCount() async throws -> Int {
        let snapshot = try await db.collection("recipes").count.getAggregation(source: .server)
        return Int(truncating: snapshot.count)
    }
    
    /// Check if recipes collection exists and has data
    func hasRecipesInFirestore() async -> Bool {
        do {
            let snapshot = try await db.collection("recipes").limit(to: 1).getDocuments()
            return !snapshot.documents.isEmpty
        } catch {
            print("❌ Error checking recipes: \(error)")
            return false
        }
    }
    
    /// Check if a specific recipe exists in Firestore
    func recipeExistsInFirestore(recipeId: String) async -> Bool {
        do {
            let doc = try await db.collection("recipes").document(recipeId).getDocument()
            return doc.exists
        } catch {
            print("❌ Error checking recipe \(recipeId): \(error)")
            return false
        }
    }
    
    // MARK: - Firebase Storage (Images)
    
    private let storage = Storage.storage()
    
    /// Upload a recipe image to Firebase Storage
    func uploadRecipeImage(imageName: String, imageData: Data) async throws -> String {
        let storageRef = storage.reference().child("recipe-images/\(imageName).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        print("📸 Uploaded image: \(imageName)")
        return downloadURL.absoluteString
    }
    
    /// Update recipe with image URL
    func updateRecipeImageURL(recipeId: String, imageURL: String) async throws {
        try await db.collection("recipes").document(recipeId).updateData([
            "imageURL": imageURL
        ])
        print("✅ Updated recipe \(recipeId) with image URL")
    }
    
    /// Check if a recipe has an image URL in Firestore
    func recipeHasImageURL(recipeId: String) async -> Bool {
        do {
            let doc = try await db.collection("recipes").document(recipeId).getDocument()
            if let data = doc.data(), let imageURL = data["imageURL"] as? String, !imageURL.isEmpty {
                return true
            }
            return false
        } catch {
            return false
        }
    }
    
    /// Check if any recipe has images uploaded
    func hasImagesInStorage() async -> Bool {
        do {
            // Check if at least one recipe has an imageURL
            let snapshot = try await db.collection("recipes")
                .whereField("imageURL", isNotEqualTo: "")
                .limit(to: 1)
                .getDocuments()
            return !snapshot.documents.isEmpty
        } catch {
            // If query fails, check differently
            do {
                let snapshot = try await db.collection("recipes").limit(to: 1).getDocuments()
                if let doc = snapshot.documents.first,
                   let data = doc.data() as? [String: Any],
                   let imageURL = data["imageURL"] as? String,
                   !imageURL.isEmpty {
                    return true
                }
            } catch {
                print("❌ Error checking for images: \(error)")
            }
            return false
        }
    }
}

// MARK: - Firestore Recipe Model

struct FirestoreRecipe: Identifiable, Codable {
    @DocumentID var documentId: String?
    let id: String
    let name: String
    let isForFamily: Bool
    let dietTags: [String]
    let chefLevel: String  // Simplified to single level for filtering
    let chefLevels: [String]  // Original array for display
    let cookTimeMinutes: Int
    let description: String
    let ingredients: [String]
    let steps: [String]
    let foodTags: [String]
    let imageName: String
    let cuisine: String
    var imageURL: String?  // Cloud storage URL (nil = use local asset)
    
    enum CodingKeys: String, CodingKey {
        case documentId
        case id, name, isForFamily, dietTags, chefLevel, chefLevels
        case cookTimeMinutes, description, ingredients, steps
        case foodTags, imageName, cuisine, imageURL
    }
}
