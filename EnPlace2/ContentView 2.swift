import SwiftUI
import Combine

// MARK: - Brand Colors

extension Color {
    // Primary brand colors
    static let enplaceTerracotta = Color(red: 0.82, green: 0.45, blue: 0.35)      // Warm terracotta
    static let enplaceSage = Color(red: 0.56, green: 0.64, blue: 0.52)            // Muted sage green
    static let enplaceCream = Color(red: 0.98, green: 0.96, blue: 0.92)           // Warm cream
    
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
    let id = UUID()
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
}

enum DietTag: String, CaseIterable, Identifiable, Codable {
    case none = "No preference"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten-free"

    var id: String { rawValue }
}

enum ChefLevel: String, CaseIterable, Identifiable, Codable {
    case lineCook = "Line cook"
    case sousChef = "Sous chef"
    case executiveChef = "Executive chef"

    var id: String { rawValue }
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
    case beef = "Beef"
    case chicken = "Chicken"
    case fish = "Fish"
    case pork = "Pork"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    
    var id: String { rawValue }
    
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
    @Published private(set) var currentIndex: Int = 0

    private let allRecipes: [Recipe]

    init() {
                self.allRecipes = [
            Recipe(
                name: "Baked Italian Sausage and Peppers",
                isForFamily: true,
                dietTags: [.none],
                chefLevels: [.lineCook, .sousChef],
                cookTimeMinutes: 35,
                description: "Sheet pan sausage with bell peppers and onions, tossed in olive oil and Italian herbs.",
                ingredients: [
                    "4 Italian sausages",
                    "2 bell peppers, sliced",
                    "1 yellow onion, sliced",
                    "2 tbsp olive oil",
                    "1 tsp Italian seasoning",
                    "Salt & pepper"
                ],
                steps: [
                    "Preheat oven to 400°F (200°C).",
                    "Slice peppers and onion and toss with olive oil, seasoning, salt, and pepper.",
                    "Add sausages to a sheet pan with the vegetables.",
                    "Bake for 25–30 minutes, flipping sausages halfway through.",
                    "Serve with crusty bread or over rice."
                ],
                foodTags: [.pork],
                imageName: "sausage-peppers"
            ),
            Recipe(
                name: "Chicken Tikka Masala",
                isForFamily: false,
                dietTags: [.none],
                chefLevels: [.sousChef, .executiveChef],
                cookTimeMinutes: 45,
                description: "Creamy tomato-based curry with marinated chicken, served over basmati rice.",
                ingredients: [
                    "1 lb chicken thighs, cubed",
                    "1 cup plain yogurt",
                    "2 tbsp garam masala",
                    "1 tsp turmeric",
                    "1 tsp cumin",
                    "1 onion, diced",
                    "2 cloves garlic, minced",
                    "1 tbsp grated ginger",
                    "1 can (14 oz) tomato sauce",
                    "1 cup heavy cream"
                ],
                steps: [
                    "Marinate chicken in yogurt and spices for at least 30 minutes.",
                    "Sauté onion, garlic, and ginger in a pan until softened.",
                    "Add marinated chicken and cook until browned.",
                    "Pour in tomato sauce and simmer for 15–20 minutes.",
                    "Stir in cream and simmer for another 5 minutes.",
                    "Serve over rice with naan."
                ],
                foodTags: [.chicken],
                imageName: "tikka-masala"
            ),
            Recipe(
                name: "Sheet Pan Veggie Tacos",
                isForFamily: true,
                dietTags: [.vegetarian, .glutenFree],
                chefLevels: [.lineCook],
                cookTimeMinutes: 25,
                description: "Roasted peppers, onions, and black beans served in warm tortillas.",
                ingredients: [
                    "2 bell peppers, sliced",
                    "1 red onion, sliced",
                    "1 can black beans, drained and rinsed",
                    "2 tbsp olive oil",
                    "1 tsp chili powder",
                    "1 tsp cumin",
                    "Corn tortillas"
                ],
                steps: [
                    "Preheat oven to 425°F (220°C).",
                    "Toss peppers, onion, and beans with olive oil and spices.",
                    "Spread on a sheet pan and roast for 15–20 minutes.",
                    "Warm tortillas and fill with roasted veggies.",
                    "Top with salsa, cheese, or avocado as desired."
                ],
                foodTags: [.vegetarian],
                imageName: "veggie-tacos"
            ),
            Recipe(
                name: "Lemon Garlic Salmon with Roasted Broccoli",
                isForFamily: false,
                dietTags: [.none, .glutenFree],
                chefLevels: [.lineCook, .sousChef],
                cookTimeMinutes: 30,
                description: "Roasted salmon fillets with lemon, garlic, and broccoli florets.",
                ingredients: [
                    "2 salmon fillets",
                    "2 cups broccoli florets",
                    "2 tbsp olive oil",
                    "2 cloves garlic, minced",
                    "1 lemon, sliced",
                    "Salt & pepper"
                ],
                steps: [
                    "Preheat oven to 400°F (200°C).",
                    "Toss broccoli with olive oil, salt, and pepper.",
                    "Place salmon on a sheet pan, top with garlic and lemon slices.",
                    "Add broccoli around salmon.",
                    "Bake for 15–18 minutes until salmon flakes easily."
                ],
                foodTags: [.fish],
                imageName: "lemon-salmon"
            ),
            Recipe(
                name: "One-Pot Creamy Tuscan Chicken Pasta",
                isForFamily: true,
                dietTags: [.none],
                chefLevels: [.sousChef],
                cookTimeMinutes: 35,
                description: "Creamy pasta with chicken, spinach, and sun-dried tomatoes in one pot.",
                ingredients: [
                    "1 lb chicken breast, sliced",
                    "8 oz short pasta",
                    "2 cups chicken broth",
                    "1 cup heavy cream",
                    "1/2 cup sun-dried tomatoes, chopped",
                    "2 cups baby spinach",
                    "2 cloves garlic, minced"
                ],
                steps: [
                    "Sauté chicken until lightly browned.",
                    "Add garlic and cook briefly.",
                    "Add pasta, broth, cream, and sun-dried tomatoes.",
                    "Simmer until pasta is cooked.",
                    "Stir in spinach until wilted."
                ],
                foodTags: [.chicken],
                imageName: "tuscan-pasta"
            ),
            Recipe(
                name: "Black Bean & Sweet Potato Chili",
                isForFamily: true,
                dietTags: [.vegetarian, .glutenFree],
                chefLevels: [.lineCook],
                cookTimeMinutes: 40,
                description: "Hearty vegetarian chili with black beans and sweet potatoes.",
                ingredients: [
                    "1 large sweet potato, cubed",
                    "1 can black beans, drained",
                    "1 can diced tomatoes",
                    "1 onion, diced",
                    "2 cloves garlic, minced",
                    "2 tbsp chili powder",
                    "1 tsp cumin",
                    "2 cups vegetable broth"
                ],
                steps: [
                    "Sauté onion and garlic until softened.",
                    "Add sweet potato and spices, cook a few minutes.",
                    "Add beans, tomatoes, and broth.",
                    "Simmer 25–30 minutes until sweet potato is tender."
                ],
                foodTags: [.vegetarian],
                imageName: "sweet-potato-chili"
            ),
            Recipe(
                name: "Beef & Broccoli Stir Fry",
                isForFamily: false,
                dietTags: [.none],
                chefLevels: [.sousChef],
                cookTimeMinutes: 25,
                description: "Quick stir fry with sliced beef, broccoli, and a savory sauce.",
                ingredients: [
                    "3/4 lb flank steak, sliced thin",
                    "2 cups broccoli florets",
                    "2 tbsp soy sauce",
                    "1 tbsp oyster sauce",
                    "1 tbsp cornstarch",
                    "2 cloves garlic, minced",
                    "1 tbsp vegetable oil"
                ],
                steps: [
                    "Marinate beef in soy sauce and cornstarch.",
                    "Stir-fry beef until browned, remove from pan.",
                    "Stir-fry broccoli and garlic.",
                    "Return beef and add oyster sauce, toss to coat."
                ],
                foodTags: [.beef],
                imageName: "beef-broccoli"
            ),
            Recipe(
                name: "Crispy Pork Carnitas Tacos",
                isForFamily: true,
                dietTags: [.none],
                chefLevels: [.sousChef],
                cookTimeMinutes: 50,
                description: "Slow-simmered pork crisped under the broiler and served in tortillas.",
                ingredients: [
                    "2 lbs pork shoulder, cubed",
                    "1 onion, quartered",
                    "2 cloves garlic",
                    "1 orange, juiced",
                    "1 tsp cumin",
                    "1 tsp oregano",
                    "Corn tortillas"
                ],
                steps: [
                    "Simmer pork with onion, garlic, orange juice, and spices until tender.",
                    "Shred pork and spread on a sheet pan.",
                    "Broil until edges are crispy.",
                    "Serve in warm tortillas with toppings."
                ],
                foodTags: [.pork],
                imageName: "carnitas"
            ),
            Recipe(
                name: "Margherita Flatbread Pizza",
                isForFamily: false,
                dietTags: [.vegetarian],
                chefLevels: [.lineCook],
                cookTimeMinutes: 20,
                description: "Flatbread topped with tomato sauce, fresh mozzarella, and basil.",
                ingredients: [
                    "2 flatbreads",
                    "1/2 cup tomato sauce",
                    "4 oz fresh mozzarella, sliced",
                    "Fresh basil leaves",
                    "Olive oil"
                ],
                steps: [
                    "Preheat oven to 425°F (220°C).",
                    "Spread sauce on flatbreads.",
                    "Top with mozzarella slices.",
                    "Bake 8–10 minutes until cheese melts.",
                    "Garnish with basil and drizzle with olive oil."
                ],
                foodTags: [.vegetarian],
                imageName: "margherita-pizza"
            ),
            Recipe(
                name: "Peanut Noodle Veggie Bowls",
                isForFamily: false,
                dietTags: [.vegan],
                chefLevels: [.sousChef],
                cookTimeMinutes: 30,
                description: "Rice noodles with a peanut sauce and crunchy veggies.",
                ingredients: [
                    "8 oz rice noodles",
                    "1 red bell pepper, sliced",
                    "1 cup shredded carrots",
                    "1 cucumber, sliced",
                    "1/3 cup peanut butter",
                    "2 tbsp soy sauce",
                    "1 tbsp lime juice",
                    "1 tbsp maple syrup",
                    "Water to thin"
                ],
                steps: [
                    "Cook rice noodles according to package.",
                    "Whisk peanut butter, soy sauce, lime, and syrup with water.",
                    "Toss noodles with sauce and veggies.",
                    "Serve with extra lime wedges."
                ],
                foodTags: [.vegan],
                imageName: "peanut-noodles"
            ),
            Recipe(
                name: "Shrimp Fried Rice",
                isForFamily: true,
                dietTags: [.none],
                chefLevels: [.sousChef],
                cookTimeMinutes: 30,
                description: "Fried rice with shrimp, peas, carrots, and eggs.",
                ingredients: [
                    "3 cups cooked rice (day-old preferred)",
                    "8 oz shrimp, peeled",
                    "1/2 cup frozen peas and carrots",
                    "2 eggs, beaten",
                    "2 tbsp soy sauce",
                    "2 tbsp vegetable oil",
                    "2 green onions, sliced"
                ],
                steps: [
                    "Scramble eggs in a hot pan, set aside.",
                    "Stir-fry shrimp until pink, remove.",
                    "Stir-fry rice with peas and carrots.",
                    "Add soy sauce, eggs, shrimp, and green onions and toss."
                ],
                foodTags: [.fish],
                imageName: "shrimp-fried-rice"
            ),
            Recipe(
                name: "BBQ Chicken Sheet Pan Dinner",
                isForFamily: true,
                dietTags: [.none, .glutenFree],
                chefLevels: [.lineCook],
                cookTimeMinutes: 35,
                description: "BBQ chicken thighs roasted with potatoes and green beans.",
                ingredients: [
                    "6 chicken thighs",
                    "1/2 cup BBQ sauce",
                    "1 lb baby potatoes, halved",
                    "2 cups green beans, trimmed",
                    "2 tbsp olive oil",
                    "Salt & pepper"
                ],
                steps: [
                    "Preheat oven to 400°F (200°C).",
                    "Toss potatoes and green beans with olive oil, salt, and pepper.",
                    "Spread on sheet pan with chicken thighs.",
                    "Brush chicken with BBQ sauce.",
                    "Roast 30–35 minutes until chicken is cooked through."
                ],
                foodTags: [.chicken],
                imageName: "bbq-chicken"
            ),
            Recipe(
                name: "Veggie Frittata",
                isForFamily: false,
                dietTags: [.vegetarian, .glutenFree],
                chefLevels: [.lineCook],
                cookTimeMinutes: 25,
                description: "Egg-based frittata with spinach, peppers, and cheese.",
                ingredients: [
                    "6 eggs",
                    "1/2 cup shredded cheese",
                    "1 cup spinach",
                    "1/2 red bell pepper, diced",
                    "1/4 cup milk",
                    "Salt & pepper"
                ],
                steps: [
                    "Preheat oven to 375°F (190°C).",
                    "Whisk eggs, milk, salt, and pepper.",
                    "Add veggies and cheese.",
                    "Pour into greased oven-safe skillet.",
                    "Bake 15–18 minutes until set."
                ],
                foodTags: [.vegetarian],
                imageName: "frittata"
            ),
            Recipe(
                name: "Lentil Bolognese over Pasta",
                isForFamily: true,
                dietTags: [.vegan],
                chefLevels: [.sousChef],
                cookTimeMinutes: 40,
                description: "Hearty tomato sauce with lentils served over pasta.",
                ingredients: [
                    "1 cup dry lentils",
                    "1 jar marinara sauce",
                    "1 onion, diced",
                    "2 cloves garlic, minced",
                    "2 tbsp olive oil",
                    "8 oz pasta"
                ],
                steps: [
                    "Cook lentils until tender.",
                    "Sauté onion and garlic, then add marinara and lentils.",
                    "Simmer 10–15 minutes.",
                    "Cook pasta and serve topped with lentil sauce."
                ],
                foodTags: [.vegan],
                imageName: "lentil-bolognese"
            ),
            Recipe(
                name: "Teriyaki Tofu Rice Bowls",
                isForFamily: false,
                dietTags: [.vegan, .glutenFree],
                chefLevels: [.sousChef],
                cookTimeMinutes: 30,
                description: "Crispy tofu with teriyaki sauce over rice and steamed veggies.",
                ingredients: [
                    "1 block extra-firm tofu, cubed",
                    "2 tbsp cornstarch",
                    "2 tbsp soy or tamari sauce",
                    "2 tbsp teriyaki sauce",
                    "2 cups cooked rice",
                    "2 cups steamed broccoli"
                ],
                steps: [
                    "Press tofu, then toss with cornstarch.",
                    "Pan-fry until crispy.",
                    "Add teriyaki sauce and coat.",
                    "Serve over rice with steamed broccoli."
                ],
                foodTags: [.vegan],
                imageName: "teriyaki-tofu"
            ),
            Recipe(
                name: "Greek Chicken Bowls",
                isForFamily: false,
                dietTags: [.none, .glutenFree],
                chefLevels: [.lineCook, .sousChef],
                cookTimeMinutes: 30,
                description: "Bowls with marinated chicken, cucumbers, tomatoes, and feta over rice.",
                ingredients: [
                    "1 lb chicken breast, cubed",
                    "1/4 cup olive oil",
                    "Juice of 1 lemon",
                    "1 tsp oregano",
                    "2 cups cooked rice",
                    "1 cucumber, chopped",
                    "1 cup cherry tomatoes, halved",
                    "1/2 cup feta cheese"
                ],
                steps: [
                    "Marinate chicken in olive oil, lemon, and oregano.",
                    "Cook chicken in a skillet until done.",
                    "Assemble bowls with rice, chicken, veggies, and feta."
                ],
                foodTags: [.chicken],
                imageName: "greek-chicken"
            ),
            Recipe(
                name: "Slow Cooker Beef Stew",
                isForFamily: true,
                dietTags: [.none, .glutenFree],
                chefLevels: [.lineCook],
                cookTimeMinutes: 480,
                description: "Comforting beef stew with potatoes, carrots, and onions.",
                ingredients: [
                    "2 lbs stew beef, cubed",
                    "4 carrots, sliced",
                    "4 potatoes, cubed",
                    "1 onion, chopped",
                    "3 cups beef broth",
                    "2 tbsp tomato paste",
                    "1 tsp thyme",
                    "Salt & pepper"
                ],
                steps: [
                    "Add all ingredients to a slow cooker.",
                    "Cook on low 8 hours or high 4–5 hours.",
                    "Adjust seasoning before serving."
                ],
                foodTags: [.beef],
                imageName: "beef-stew"
            ),
            Recipe(
                name: "Fish Taco Bowls",
                isForFamily: false,
                dietTags: [.none, .glutenFree],
                chefLevels: [.lineCook],
                cookTimeMinutes: 25,
                description: "Seasoned fish over rice with slaw and lime crema.",
                ingredients: [
                    "3/4 lb white fish fillets",
                    "1 tsp chili powder",
                    "1 tsp cumin",
                    "2 cups cooked rice",
                    "1 cup shredded cabbage",
                    "1/4 cup sour cream",
                    "Juice of 1 lime"
                ],
                steps: [
                    "Season fish with chili powder and cumin.",
                    "Bake or pan-cook until flaky.",
                    "Mix cabbage with a bit of lime and salt.",
                    "Stir lime juice into sour cream for crema.",
                    "Serve fish over rice with slaw and crema."
                ],
                foodTags: [.fish],
                imageName: "fish-tacos"
            ),
            Recipe(
                name: "Chickpea Coconut Curry",
                isForFamily: true,
                dietTags: [.vegan, .glutenFree],
                chefLevels: [.lineCook],
                cookTimeMinutes: 30,
                description: "Creamy curry with chickpeas and spinach in coconut milk.",
                ingredients: [
                    "1 can chickpeas, drained",
                    "1 can coconut milk",
                    "1 onion, diced",
                    "2 tbsp curry powder",
                    "2 cups baby spinach",
                    "1 tbsp oil"
                ],
                steps: [
                    "Sauté onion in oil until soft.",
                    "Stir in curry powder.",
                    "Add chickpeas and coconut milk, simmer 10–15 minutes.",
                    "Stir in spinach until wilted."
                ],
                foodTags: [.vegan],
                imageName: "chickpea-curry"
            ),
            Recipe(
                name: "Beef Meatballs with Zoodles",
                isForFamily: false,
                dietTags: [.none, .glutenFree],
                chefLevels: [.sousChef],
                cookTimeMinutes: 35,
                description: "Oven-baked beef meatballs served over zucchini noodles and marinara.",
                ingredients: [
                    "1 lb ground beef",
                    "1 egg",
                    "1/4 cup breadcrumbs (or GF crumbs)",
                    "1 tsp Italian seasoning",
                    "2 zucchinis, spiralized",
                    "1 jar marinara sauce"
                ],
                steps: [
                    "Preheat oven to 400°F (200°C).",
                    "Mix beef, egg, crumbs, seasoning, and form meatballs.",
                    "Bake 15–20 minutes until cooked through.",
                    "Warm marinara and sauté zoodles briefly.",
                    "Serve meatballs over zoodles with sauce."
                ],
                foodTags: [.beef],
                imageName: "meatballs-zoodles"
            )
        ]
        
        

        self.recipes = allRecipes
        
        let likedNames = PersistenceManager.loadLikedRecipeNames()
        self.likedRecipes = allRecipes.filter { likedNames.contains($0.name) }
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
    @State private var preferences = PersistenceManager.loadPreferences() ?? UserPreferences()
    @State private var hasCompletedOnboarding = PersistenceManager.loadPreferences() != nil

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView(viewModel: viewModel, preferences: $preferences)
            } else {
                OnboardingView(preferences: $preferences) {
                    hasCompletedOnboarding = true
                    PersistenceManager.savePreferences(preferences)
                    viewModel.applyFilters(preferences)
                }
            }
        }
        .onAppear {
            if hasCompletedOnboarding {
                viewModel.applyFilters(preferences)
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
        Image(systemName: "heart.fill")
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
            : preferences.foodPreferences.map { $0.rawValue }.joined(separator: ", ")
        
        let glutenText = preferences.isGlutenFree ? " • GF" : ""

        return VStack(alignment: .leading, spacing: 4) {
            Text("Your kitchen profile")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(preferences.householdType.label) • \(foodText)\(glutenText) • \(preferences.chefLevel.rawValue) • \(preferences.time.rawValue)")
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
                        Text(tag.rawValue.uppercased())
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
                        Text(level.rawValue)
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
            List {
                if viewModel.likedRecipes.isEmpty {
                    Text("Meals you both love will show up here.\nFor now, this shows what you've liked.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 40)
                } else {
                    ForEach(viewModel.likedRecipes) { recipe in
                        NavigationLink(recipe.name) {
                            RecipeDetailView(recipe: recipe)
                        }
                    }
                }
            }
            .navigationTitle("Recipe Box")
        }
    }
}

// MARK: - Recipe Detail

struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        ScrollView {
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
                        Toggle(food.rawValue, isOn: binding(for: food))
                    }
                }
                
                Section("Dietary restrictions") {
                    Toggle("Gluten-free only", isOn: $preferences.isGlutenFree)
                }

                Section("Chef level") {
                    Picker("Chef level", selection: $preferences.chefLevel) {
                        ForEach(ChefLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
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
                    Text(food.rawValue)
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
                    Text(level.rawValue).tag(level)
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



