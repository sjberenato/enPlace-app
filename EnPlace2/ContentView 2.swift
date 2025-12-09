import SwiftUI
import Combine

// MARK: - Brand Colors

extension Color {
    // Primary brand colors
    static let enplaceTerracotta = Color(red: 0.82, green: 0.45, blue: 0.35)      // Warm terracotta
    static let enplaceSage = Color(red: 0.56, green: 0.64, blue: 0.52)            // Muted sage green
    static let enplaceCream = Color(red: 0.976, green: 0.965, blue: 0.898)
               // Warm cream
    
    // Supporting colors
    static let enplaceCharcoal = Color(red: 0.2, green: 0.2, blue: 0.18)          // Dark text
    static let enplaceTerracottaLight = Color(red: 0.82, green: 0.45, blue: 0.35).opacity(0.15)
    static let enplaceSageLight = Color(red: 0.56, green: 0.64, blue: 0.52).opacity(0.15)
}

// MARK: - App Theme

struct AppTheme {
    static let primary = Color.enplaceTerracotta
    static let secondary = Color.enplaceSage
    static let background = Color.enplaceCream
    static let cardBackground = Color.white
    static let textPrimary = Color.enplaceCharcoal
    static let textSecondary = Color.enplaceCharcoal.opacity(0.6)
}

// MARK: - Recipe Models

struct Recipe: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    let isForFamily: Bool
    let dietTags: [DietTag]
    let chefLevels: [ChefLevel]
    let cookTimeMinutes: Int
    let description: String
    let ingredients: [String]
    let steps: [String]
    let foodTags: [FoodPreference]
    let imageName: String
    
    // Custom decoder - generates UUID since it's not in JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.isForFamily = try container.decode(Bool.self, forKey: .isForFamily)
        self.dietTags = try container.decode([DietTag].self, forKey: .dietTags)
        self.chefLevels = try container.decode([ChefLevel].self, forKey: .chefLevels)
        self.cookTimeMinutes = try container.decode(Int.self, forKey: .cookTimeMinutes)
        self.description = try container.decode(String.self, forKey: .description)
        self.ingredients = try container.decode([String].self, forKey: .ingredients)
        self.steps = try container.decode([String].self, forKey: .steps)
        self.foodTags = try container.decode([FoodPreference].self, forKey: .foodTags)
        self.imageName = try container.decode(String.self, forKey: .imageName)
    }
}

enum DietTag: String, CaseIterable, Identifiable, Codable {
    case none
    case vegetarian
    case vegan
    case glutenFree
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "No preference"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .glutenFree: return "Gluten-free"
        }
    }
}

enum ChefLevel: String, CaseIterable, Identifiable, Codable {
    case lineCook
    case sousChef
    case executiveChef
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .lineCook: return "Line cook"
        case .sousChef: return "Sous chef"
        case .executiveChef: return "Executive chef"
        }
    }
}

enum HouseholdType: String, CaseIterable, Identifiable, Codable {
    case couple = "Couple"
    case family = "Family"

    var id: String { rawValue }
    var label: String { rawValue }
}

enum TimePreference: String, CaseIterable, Identifiable, Codable {
    case under20 = "Under 20 min"
    case between20And40 = "20–40 min"
    case over40 = "40+ min"

    var id: String { rawValue }
}

enum FoodPreference: String, CaseIterable, Identifiable, Hashable, Codable {
    case beef
    case chicken
    case fish
    case pork
    case vegetarian
    case vegan
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .beef: return "Beef"
        case .chicken: return "Chicken"
        case .fish: return "Fish"
        case .pork: return "Pork"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        }
    }
    
    var icon: String {
        switch self {
        case .beef: return "Steak"
        case .chicken: return "Chicken"
        case .fish: return "Fish"
        case .pork: return "Pig"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        }
    }
    
    var subtitle: String {
        switch self {
        case .beef: return "Steaks, burgers, roasts"
        case .chicken: return "Breasts, thighs, tenders"
        case .fish: return "Salmon, cod, shrimp"
        case .pork: return "Chops, sausage, bacon"
        case .vegetarian: return "Eggs, dairy, no meat"
        case .vegan: return "Fully plant-based"
        }
    }
    
    var iconSystemName: String {
        switch self {
        case .beef: return "fork.knife"
        case .chicken: return "bird.fill"
        case .fish: return "fish.fill"
        case .pork: return "flame.fill"
        case .vegetarian: return "leaf.circle.fill"
        case .vegan: return "leaf.fill"
        }
    }
}

// MARK: - User Preferences

struct UserPreferences: Equatable, Codable {
    var householdType: HouseholdType = .family
    var foodPreferences: Set<FoodPreference> = []
    var isGlutenFree: Bool = false
    var chefLevel: ChefLevel = .lineCook
    var time: TimePreference = .between20And40
    var chefBEmail: String = ""
}

private enum PersistenceKeys {
    static let userPreferences = "enplace_userPreferences"
    static let likedRecipeNames = "enplace_likedRecipeNames"
}

private struct PersistenceManager {
    static func savePreferences(_ preferences: UserPreferences) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(preferences) {
            UserDefaults.standard.set(data, forKey: PersistenceKeys.userPreferences)
        }
    }

    static func loadPreferences() -> UserPreferences? {
        guard let data = UserDefaults.standard.data(forKey: PersistenceKeys.userPreferences) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(UserPreferences.self, from: data)
    }

    static func saveLikedRecipes(_ recipes: [Recipe]) {
        let names = recipes.map { $0.name }
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(names) {
            UserDefaults.standard.set(data, forKey: PersistenceKeys.likedRecipeNames)
        }
    }

    static func loadLikedRecipeNames() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: PersistenceKeys.likedRecipeNames) else {
            return []
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode([String].self, from: data)) ?? []
    }
}

// MARK: - ViewModel

@MainActor
final class RecipeSwipeViewModel: ObservableObject {
    @Published private(set) var recipes: [Recipe]
    @Published private(set) var likedRecipes: [Recipe] = []
    @Published private(set) var matchedRecipes: [Recipe] = []  // Recipes both chefs liked
    @Published private(set) var currentIndex: Int = 0

    private let allRecipes: [Recipe]

    init() {
        // Load recipes from JSON file
        self.allRecipes = RecipeService.loadRecipes()
        self.recipes = allRecipes
        
        let likedNames = PersistenceManager.loadLikedRecipeNames()
        self.likedRecipes = allRecipes.filter { likedNames.contains($0.name) }
        
        // Load matches from Firebase if available
        updateMatchesFromFirebase(matchedNames: FirebaseService.shared.matchedRecipeNames)
    }

    var currentRecipe: Recipe? {
        guard currentIndex < recipes.count else { return nil }
        return recipes[currentIndex]
    }

    func swipeRight() {
        if let recipe = currentRecipe {
            if !likedRecipes.contains(recipe) {
                likedRecipes.append(recipe)
                PersistenceManager.saveLikedRecipes(likedRecipes)
                
                // Sync to Firebase
                Task {
                    try? await FirebaseService.shared.likeRecipe(recipeName: recipe.name)
                }
            }
        }
        goToNextRecipe()
    }

    func swipeLeft() {
        goToNextRecipe()
    }

    private func goToNextRecipe() {
        if currentIndex < recipes.count - 1 {
            currentIndex += 1
        }
    }
    
    /// Update matched recipes from Firebase
    func updateMatchesFromFirebase(matchedNames: [String]) {
        matchedRecipes = allRecipes.filter { matchedNames.contains($0.name) }
    }
    
    /// Update liked recipes from Firebase (for syncing)
    func updateLikesFromFirebase(likedNames: [String]) {
        likedRecipes = allRecipes.filter { likedNames.contains($0.name) }
    }

    func applyFilters(_ preferences: UserPreferences) {
        var filtered = allRecipes

        // Household
        filtered = filtered.filter { recipe in
            preferences.householdType == .family ? recipe.isForFamily : !recipe.isForFamily
        }

        // Food preferences
        if !preferences.foodPreferences.isEmpty {
            filtered = filtered.filter { recipe in
                for pref in preferences.foodPreferences {
                    switch pref {
                    case .vegan:
                        if recipe.dietTags.contains(.vegan) || recipe.foodTags.contains(.vegan) { return true }
                    case .vegetarian:
                        if recipe.dietTags.contains(.vegetarian) || recipe.dietTags.contains(.vegan) || recipe.foodTags.contains(.vegetarian) || recipe.foodTags.contains(.vegan) { return true }
                    case .beef:
                        if recipe.foodTags.contains(.beef) { return true }
                    case .chicken:
                        if recipe.foodTags.contains(.chicken) { return true }
                    case .fish:
                        if recipe.foodTags.contains(.fish) { return true }
                    case .pork:
                        if recipe.foodTags.contains(.pork) { return true }
                    }
                }
                return false
            }
        }

        // Gluten-free restriction
        if preferences.isGlutenFree {
            filtered = filtered.filter { recipe in
                recipe.dietTags.contains(.glutenFree)
            }
        }

        // Chef level
        func rank(_ level: ChefLevel) -> Int {
            switch level {
            case .lineCook: return 0
            case .sousChef: return 1
            case .executiveChef: return 2
            }
        }
        let userRank = rank(preferences.chefLevel)
        filtered = filtered.filter { recipe in
            let maxRank = recipe.chefLevels.map(rank).max() ?? 0
            return maxRank <= userRank
        }

        // Time
        filtered = filtered.filter { recipe in
            switch preferences.time {
            case .under20:
                return recipe.cookTimeMinutes <= 20
            case .between20And40:
                return recipe.cookTimeMinutes <= 40
            case .over40:
                return true
            }
        }

        self.recipes = filtered
        self.currentIndex = 0
    }
}

// MARK: - Root ContentView

struct ContentView: View {
    @StateObject private var viewModel = RecipeSwipeViewModel()
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var preferences = PersistenceManager.loadPreferences() ?? UserPreferences()
    @State private var hasCompletedOnboarding = PersistenceManager.loadPreferences() != nil
    @State private var showWelcome = true
    @State private var hasAcknowledgedInviteCode = false

    var body: some View {
        Group {
            if showWelcome {
                // Step 1: Welcome screen
                WelcomeView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showWelcome = false
                    }
                }
            } else if !firebaseService.isAuthenticated {
                // Step 2: Sign in / Sign up
                AuthContainerView()
            } else if firebaseService.currentHousehold == nil || !hasAcknowledgedInviteCode {
                // Step 3: Create or join a household (stays here until user acknowledges invite code)
                HouseholdSetupView(onContinue: {
                    withAnimation {
                        hasAcknowledgedInviteCode = true
                    }
                })
            } else if !hasCompletedOnboarding {
                // Step 4: Preferences onboarding
                OnboardingView(preferences: $preferences) {
                    hasCompletedOnboarding = true
                    PersistenceManager.savePreferences(preferences)
                    viewModel.applyFilters(preferences)
                }
            } else {
                // Step 5: Main app
                MainTabView(viewModel: viewModel, preferences: $preferences)
            }
        }
        .onAppear {
            if hasCompletedOnboarding {
                viewModel.applyFilters(preferences)
            }
        }
        // Sync matched recipes from Firebase to ViewModel
        .onChange(of: firebaseService.currentHousehold?.matches) { newMatches in
            if let matches = newMatches {
                viewModel.updateMatchesFromFirebase(matchedNames: matches)
            }
        }
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    var onContinue: () -> Void
    
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo - full width
                Image("welcome-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // Let's Cook button - right under the logo
                Button {
                    onContinue()
                } label: {
                    Text("Let's Cook")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.primary)
                                .shadow(color: AppTheme.primary.opacity(0.4), radius: 12, y: 6)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.top, 30)
                .opacity(buttonOpacity)
                
                Spacer()
            }
        }
        .onAppear {
            // Animate logo entrance
            withAnimation(.easeOut(duration: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            // Animate button with delay
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                buttonOpacity = 1.0
            }
        }
    }
}

// MARK: - Main Tab Shell

struct MainTabView: View {
    @ObservedObject var viewModel: RecipeSwipeViewModel
    @Binding var preferences: UserPreferences

    var body: some View {
        TabView {
            DiscoverView(viewModel: viewModel, preferences: preferences)
                .tabItem {
                    Label("Discover", systemImage: "hand.tap")
                }

            RecipeBoxView(viewModel: viewModel)
                .tabItem {
                    Label("Recipe Box", systemImage: "books.vertical")
                }

            PreferencesView(preferences: $preferences)
                .tabItem {
                    Label("Preferences", systemImage: "slider.horizontal.3")
                }
        }
        .onChange(of: preferences) { newValue in
            PersistenceManager.savePreferences(newValue)
            viewModel.applyFilters(newValue)
        }
    }
}

// MARK: - Discover View

struct DiscoverView: View {
    @ObservedObject var viewModel: RecipeSwipeViewModel
    let preferences: UserPreferences

    @State private var dragOffset: CGSize = .zero

    enum SwipeDirection {
        case left
        case right
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                preferencesSummary

                if viewModel.currentRecipe != nil {
                    ZStack {
                        ForEach(visibleIndices, id: \.self) { index in
                            let recipe = viewModel.recipes[index]
                            RecipeCard(recipe: recipe)
                                .scaleEffect(index == viewModel.currentIndex ? 1.0 : 0.94)
                                .offset(
                                    x: index == viewModel.currentIndex ? dragOffset.width : 0,
                                    y: index == viewModel.currentIndex ? dragOffset.height : 16
                                )
                                .rotationEffect(
                                    index == viewModel.currentIndex
                                    ? .degrees(Double(dragOffset.width / 20))
                                    : .degrees(0)
                                )
                                .shadow(radius: index == viewModel.currentIndex ? 4 : 1, y: 2)
                                .zIndex(index == viewModel.currentIndex ? 1 : 0)
                        }

                        HStack {
                            Text("NOPE")
                                .font(.headline)
                                .padding(8)
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .rotationEffect(.degrees(-15))
                                .opacity(dragOffset.width < -80 ? 1 : 0)
                                .padding(.leading, 24)
                            Spacer()
                            Text("LIKE")
                                .font(.headline)
                                .padding(8)
                                .background(Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .rotationEffect(.degrees(15))
                                .opacity(dragOffset.width > 80 ? 1 : 0)
                                .padding(.trailing, 24)
                        }
                        .padding(.top, 32)
                    }
                    .frame(maxHeight: 400)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                handleDragEnd(value)
                            }
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.currentIndex)

                    HStack(spacing: 40) {
    Button {
        triggerSwipe(.left)
    } label: {
        Image(systemName: "xmark")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 64, height: 64)
            .background(
                Circle()
                    .fill(Color.red.opacity(0.85))
                    .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
            )
    }

    Button {
        triggerSwipe(.right)
    } label: {
        Image(systemName: "hand.thumbsup.fill")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 64, height: 64)
            .background(
                Circle()
                    .fill(AppTheme.secondary)
                    .shadow(color: AppTheme.secondary.opacity(0.4), radius: 8, y: 4)
            )
    }
}
                    .font(.headline)
                } else {
                    Text("No recipes match your filters yet.\nTry adjusting your preferences.")
                        .multilineTextAlignment(.center)
                        .padding()
                }

                            Spacer()
            }
            .padding()
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Tonight's Dinner?")
        }
    }

    private var visibleIndices: [Int] {
        guard !viewModel.recipes.isEmpty else { return [] }
        let current = viewModel.currentIndex
        let next = current + 1
        var indices: [Int] = [current]
        if next < viewModel.recipes.count {
            indices.append(next)
        }
        return indices
    }

    private var preferencesSummary: some View {
        let foodText = preferences.foodPreferences.isEmpty
            ? "Any food"
            : preferences.foodPreferences.map { $0.displayName }.joined(separator: ", ")
        
        let glutenText = preferences.isGlutenFree ? " • GF" : ""

        return VStack(alignment: .leading, spacing: 4) {
            Text("Your kitchen profile")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(preferences.householdType.label) • \(foodText)\(glutenText) • \(preferences.chefLevel.displayName) • \(preferences.time.rawValue)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func handleDragEnd(_ value: DragGesture.Value) {
        let threshold: CGFloat = 120

        if value.translation.width > threshold {
            triggerSwipe(.right)
        } else if value.translation.width < -threshold {
            triggerSwipe(.left)
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                dragOffset = .zero
            }
        }
    }

    private func triggerSwipe(_ direction: SwipeDirection) {
        let horizontal: CGFloat = direction == .right ? 600 : -600

        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            dragOffset = CGSize(width: horizontal, height: 0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            switch direction {
            case .right: viewModel.swipeRight()
            case .left: viewModel.swipeLeft()
            }
            dragOffset = .zero
        }
    }
}

// MARK: - Recipe Card

// MARK: - Recipe Card

struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero Image
            ZStack(alignment: .bottomLeading) {
                // Image or gradient placeholder
                recipeImage
                
                // Gradient overlay for text readability
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                
                // Category badge
                HStack {
                    ForEach(recipe.foodTags.prefix(1), id: \.self) { tag in
                        Text(tag.displayName.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(0.5)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.primary)
                            .foregroundStyle(.white)
                            .cornerRadius(4)
                    }
                    Spacer()
                    
                    // Time badge
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                        Text("\(recipe.cookTimeMinutes) min")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .foregroundStyle(.white)
                    .cornerRadius(4)
                }
                .padding(12)
            }
            .frame(height: 200)
            .clipped()
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(recipe.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                
                // Description
                Text(recipe.description)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                
                // Bottom row
                HStack {
                    // Serving size
                    Label(
                        recipe.isForFamily ? "Family" : "Couple",
                        systemImage: recipe.isForFamily ? "person.3.fill" : "person.2.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    // Difficulty
                    ForEach(recipe.chefLevels.prefix(1)) { level in
                        Text(level.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppTheme.secondary.opacity(0.15))
                            .foregroundStyle(AppTheme.secondary)
                            .cornerRadius(6)
                    }
                }
            }
            .padding(16)
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Image View
    
    @ViewBuilder
    private var recipeImage: some View {
        // Try to load from assets, fall back to gradient
        if let uiImage = UIImage(named: recipe.imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            // Gradient placeholder based on food type
            gradientPlaceholder
        }
    }
    
    private var gradientPlaceholder: some View {
        let colors: [Color] = {
            guard let firstTag = recipe.foodTags.first else {
                return [AppTheme.primary, AppTheme.primary.opacity(0.7)]
            }
            switch firstTag {
            case .beef: return [Color(red: 0.6, green: 0.2, blue: 0.2), Color(red: 0.8, green: 0.3, blue: 0.3)]
            case .chicken: return [Color(red: 0.85, green: 0.65, blue: 0.4), Color(red: 0.95, green: 0.75, blue: 0.5)]
            case .fish: return [Color(red: 0.3, green: 0.5, blue: 0.7), Color(red: 0.4, green: 0.6, blue: 0.8)]
            case .pork: return [Color(red: 0.7, green: 0.45, blue: 0.4), Color(red: 0.85, green: 0.55, blue: 0.5)]
            case .vegetarian: return [Color(red: 0.4, green: 0.6, blue: 0.4), Color(red: 0.5, green: 0.7, blue: 0.5)]
            case .vegan: return [Color(red: 0.3, green: 0.55, blue: 0.35), Color(red: 0.4, green: 0.65, blue: 0.45)]
            }
        }()
        
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(
                Image(systemName: recipe.foodTags.first?.iconSystemName ?? "fork.knife")
                    .font(.system(size: 50))
                    .foregroundStyle(.white.opacity(0.3))
            )
    }
}

// MARK: - Recipe Box

struct RecipeBoxView: View {
    @ObservedObject var viewModel: RecipeSwipeViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Matches Tile
                    NavigationLink {
                        RecipeListView(
                            title: "Matches",
                            recipes: viewModel.matchedRecipes,
                            isMatchList: true,
                            emptyIcon: "heart.circle",
                            emptyTitle: "No matches yet!",
                            emptyMessage: "When Chef B likes the same recipes, they'll appear here."
                        )
                    } label: {
                        RecipeCollectionTile(
                            title: "Matches",
                            icon: "heart.fill",
                            recipes: viewModel.matchedRecipes,
                            accentColor: AppTheme.primary,
                            emptyMessage: "Waiting for Chef B..."
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // My Likes Tile
                    NavigationLink {
                        RecipeListView(
                            title: "My Likes",
                            recipes: viewModel.likedRecipes,
                            isMatchList: false,
                            emptyIcon: "hand.thumbsup.circle",
                            emptyTitle: "No likes yet!",
                            emptyMessage: "Swipe right on recipes you'd love to cook."
                        )
                    } label: {
                        RecipeCollectionTile(
                            title: "My Likes",
                            icon: "hand.thumbsup.fill",
                            recipes: viewModel.likedRecipes,
                            accentColor: AppTheme.secondary,
                            emptyMessage: "Start swiping to add recipes!"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Recipe Box")
        }
    }
}

// MARK: - Recipe Collection Tile

struct RecipeCollectionTile: View {
    let title: String
    let icon: String
    let recipes: [Recipe]
    let accentColor: Color
    let emptyMessage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(accentColor)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(recipes.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            
            // Thumbnail Grid
            if recipes.isEmpty {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 32))
                            .foregroundStyle(accentColor.opacity(0.3))
                        Text(emptyMessage)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                }
                .frame(height: 80)
            } else {
                // Thumbnail grid (show up to 4)
                HStack(spacing: 8) {
                    ForEach(recipes.prefix(4)) { recipe in
                        recipeThumbnail(for: recipe)
                    }
                    
                    // Fill remaining slots with empty placeholders
                    if recipes.count < 4 {
                        ForEach(0..<(4 - recipes.count), id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(accentColor.opacity(0.1))
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
    }
    
    @ViewBuilder
    private func recipeThumbnail(for recipe: Recipe) -> some View {
        Group {
            if let uiImage = UIImage(named: recipe.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [accentColor, accentColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Recipe List View (shown when tile is tapped)

struct RecipeListView: View {
    let title: String
    let recipes: [Recipe]
    let isMatchList: Bool
    let emptyIcon: String
    let emptyTitle: String
    let emptyMessage: String
    
    var body: some View {
        List {
            if recipes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: emptyIcon)
                        .font(.system(size: 50))
                        .foregroundStyle(isMatchList ? AppTheme.primary.opacity(0.5) : AppTheme.secondary.opacity(0.5))
                    Text(emptyTitle)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .listRowBackground(Color.clear)
            } else {
                ForEach(recipes) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        RecipeRowView(recipe: recipe, isMatch: isMatchList)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
    }
}

// MARK: - Recipe Row (for Recipe Box list)

struct RecipeRowView: View {
    let recipe: Recipe
    var isMatch: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail image with match indicator
            ZStack(alignment: .topTrailing) {
                Group {
                    if let uiImage = UIImage(named: recipe.imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        // Fallback gradient
                        LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Match heart badge
                if isMatch {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Circle().fill(AppTheme.primary))
                        .offset(x: 6, y: -6)
                }
            }
            
            // Recipe info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recipe.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)
                    
                    if isMatch {
                        Spacer()
                        Text("It's a match!")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AppTheme.primary))
                    }
                }
                
                HStack(spacing: 8) {
                    Label("\(recipe.cookTimeMinutes) min", systemImage: "clock")
                    Label(recipe.isForFamily ? "Family" : "Couple", 
                          systemImage: recipe.isForFamily ? "person.3.fill" : "person.2.fill")
                }
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Recipe Detail

struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image
                ZStack(alignment: .bottomLeading) {
                    Group {
                        if let uiImage = UIImage(named: recipe.imageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    
                    // Gradient overlay
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .frame(height: 250)
                
                // Content
                VStack(alignment: .leading, spacing: 16) {
                    Text(recipe.name)
                        .font(.title)
                        .bold()

                    Text(recipe.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Label("\(recipe.cookTimeMinutes) min", systemImage: "clock")
                        if recipe.isForFamily {
                            Label("Family", systemImage: "person.3")
                        } else {
                            Label("Couple", systemImage: "person.2")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Divider()

                    Text("Ingredients")
                        .font(.headline)

                    ForEach(recipe.ingredients, id: \.self) { ingredient in
                        HStack(alignment: .top) {
                            Text("•")
                            Text(ingredient)
                        }
                    }

                    Divider()

                    Text("Steps")
                        .font(.headline)

                    ForEach(Array(recipe.steps.enumerated()), id: \.element) { index, step in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .bold()
                            Text(step)
                        }
                    }

                    Divider()

                    Button {
                        // Placeholder for future Instacart integration
                    } label: {
                        HStack {
                            Spacer()
                            Text("Send Ingredients to Instacart (Coming Soon)")
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preferences Screen

struct PreferencesView: View {
    @Binding var preferences: UserPreferences

    var body: some View {
        NavigationStack {
            Form {
                Section("Who are you cooking for?") {
                    Picker("Cooking for", selection: $preferences.householdType) {
                        ForEach(HouseholdType.allCases) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Food preferences") {
                    ForEach(FoodPreference.allCases) { food in
                        Toggle(food.displayName, isOn: binding(for: food))
                    }
                }
                
                Section("Dietary restrictions") {
                    Toggle("Gluten-free only", isOn: $preferences.isGlutenFree)
                }

                Section("Chef level") {
                    Picker("Chef level", selection: $preferences.chefLevel) {
                        ForEach(ChefLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }

                Section("Time to cook") {
                    Picker("Time available", selection: $preferences.time) {
                        ForEach(TimePreference.allCases) { time in
                            Text(time.rawValue).tag(time)
                        }
                    }
                }
            }
            .navigationTitle("Preferences")
        }
    }

    private func binding(for food: FoodPreference) -> Binding<Bool> {
        Binding(
            get: { preferences.foodPreferences.contains(food) },
            set: { isOn in
                if isOn { preferences.foodPreferences.insert(food) }
                else { preferences.foodPreferences.remove(food) }
            }
        )
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @Binding var preferences: UserPreferences
    var onFinished: () -> Void
    
    @State private var step: Int = 1
    private let totalSteps: Int = 5
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ProgressView(value: Double(step), total: Double(totalSteps))
                    .padding(.top)
                
                Group {
                    switch step {
                    case 1:
                        OnboardingHouseholdStep(householdType: $preferences.householdType)
                    case 2:
                        OnboardingFoodPreferencesStep(
                            foodPreferences: $preferences.foodPreferences,
                            isGlutenFree: $preferences.isGlutenFree
                        )
                    case 3:
                        OnboardingChefLevelStep(chefLevel: $preferences.chefLevel)
                    case 4:
                        OnboardingTimeStep(timePreference: $preferences.time)
                    default:
                        OnboardingChefBStep(chefBEmail: $preferences.chefBEmail)
                    }
                    
                    Spacer()
                    
                    HStack {
                        if step > 1 {
                            Button("Back") {
                                withAnimation { step -= 1 }
                            }
                        }
                        
                        Spacer()
                        
                        Button(step == totalSteps ? "Get started" : "Next") {
                            withAnimation {
                                if step == totalSteps {
                                    onFinished()
                                } else {
                                    step += 1
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.primary)
                    }
                }
                .padding()
                .navigationTitle("Your kitchen profile")
            }
        }
    }
}

struct OnboardingHouseholdStep: View {
    @Binding var householdType: HouseholdType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Who are you cooking for?")
                .font(.title2)
                .bold()
            
            Text("We'll tailor meals for a couple or a family.")
                .foregroundStyle(.secondary)
            
            Picker("Cooking for", selection: $householdType) {
                ForEach(HouseholdType.allCases) { type in
                    Text(type.label).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OnboardingFoodPreferencesStep: View {
    @Binding var foodPreferences: Set<FoodPreference>
    @Binding var isGlutenFree: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("What do you like to eat?")
                .font(.title2)
                .bold()
            
            Text("Select all that apply to your household.")
                .foregroundStyle(.secondary)
            
            foodGrid
            
            Divider()
                .padding(.vertical, 8)
            
            glutenFreeToggle
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Subviews
    
    private var foodGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(FoodPreference.allCases) { food in
                foodButton(for: food)
            }
        }
    }
    
    private func foodButton(for food: FoodPreference) -> some View {
        let selected = foodPreferences.contains(food)
        
        return Button {
            toggle(food)
        } label: {
            HStack(spacing: 8) {
                Image(food.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(food.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? AppTheme.primary.opacity(0.15) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? AppTheme.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var glutenFreeToggle: some View {
        Toggle(isOn: $isGlutenFree) {
            HStack(spacing: 8) {
                Image(systemName: "leaf.arrow.triangle.circlepath")
                    .foregroundStyle(AppTheme.secondary)
                Text("Gluten-free only")
                    .font(.subheadline)
            }
        }
        .tint(AppTheme.secondary)
    }
    
    // MARK: - Actions
    
    private func toggle(_ food: FoodPreference) {
        if foodPreferences.contains(food) {
            foodPreferences.remove(food)
        } else {
            foodPreferences.insert(food)
        }
    }
}

struct OnboardingChefLevelStep: View {
    @Binding var chefLevel: ChefLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's your chef level?")
                .font(.title2)
                .bold()
            
            Text("We'll match recipes to your comfort level in the kitchen.")
                .foregroundStyle(.secondary)
            
            Picker("Chef level", selection: $chefLevel) {
                ForEach(ChefLevel.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.inline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OnboardingTimeStep: View {
    @Binding var timePreference: TimePreference
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How much time do you usually have?")
                .font(.title2)
                .bold()
            
            Text("We'll focus on recipes that fit your real weeknights.")
                .foregroundStyle(.secondary)
            
            Picker("Time available", selection: $timePreference) {
                ForEach(TimePreference.allCases) { time in
                    Text(time.rawValue).tag(time)
                }
            }
            .pickerStyle(.inline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OnboardingChefBStep: View {
    @Binding var chefBEmail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Who's your co-chef?")
                .font(.title2)
                .bold()
            
            Text("Add the email of Chef B so EnPlace can start finding meals you'll both love.")
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Chef B's email")
                    .font(.headline)
                
                TextField("chef-b@example.com", text: $chefBEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
            }
            
            Text("In a later version, EnPlace will email Chef B a link so they can swipe too. For now, we're just saving this to your profile.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}



