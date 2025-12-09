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
    let createdAt: Date
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
    
    /// Join an existing household (Chef B)
    @MainActor
    func joinHousehold(inviteCode: String) async throws {
        guard var user = currentUser else {
            throw NSError(domain: "EnPlace", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
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
              let householdId = user.householdId,
              var household = currentHousehold else { return }
        
        // Add to appropriate likes array
        if user.isChefA {
            if !household.chefALikes.contains(recipeName) {
                household.chefALikes.append(recipeName)
            }
        } else {
            if !household.chefBLikes.contains(recipeName) {
                household.chefBLikes.append(recipeName)
            }
        }
        
        // Check for new match
        if household.chefALikes.contains(recipeName) && household.chefBLikes.contains(recipeName) {
            if !household.matches.contains(recipeName) {
                household.matches.append(recipeName)
                print("🎉 NEW MATCH: \(recipeName)")
            }
        }
        
        // Save to Firestore
        let data = try Firestore.Encoder().encode(household)
        try await db.collection("households").document(householdId).setData(data)
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
}
