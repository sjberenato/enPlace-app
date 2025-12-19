import SwiftUI
import Combine
import FirebaseFirestore

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
    let cuisine: Cuisine
    var imageURL: String?  // Cloud storage URL (nil = use local asset)
    
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
        self.cuisine = try container.decodeIfPresent(Cuisine.self, forKey: .cuisine) ?? .other
        self.imageURL = nil  // Local JSON doesn't have URLs
    }
    
    // Manual initializer for creating from Firestore data
    init(id: UUID, name: String, isForFamily: Bool, dietTags: [DietTag], chefLevels: [ChefLevel], cookTimeMinutes: Int, description: String, ingredients: [String], steps: [String], foodTags: [FoodPreference], imageName: String, cuisine: Cuisine, imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.isForFamily = isForFamily
        self.dietTags = dietTags
        self.chefLevels = chefLevels
        self.cookTimeMinutes = cookTimeMinutes
        self.description = description
        self.ingredients = ingredients
        self.steps = steps
        self.foodTags = foodTags
        self.imageName = imageName
        self.cuisine = cuisine
        self.imageURL = imageURL
    }
}

enum DietTag: String, CaseIterable, Identifiable, Codable {
    case none
    case vegetarian
    case vegan
    case glutenFree
    case dairyFree

    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "No preference"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .glutenFree: return "Gluten-free"
        case .dairyFree: return "Dairy-free"
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
    case seafood
    case pork
    case lamb
    case vegetarian
    case vegan
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .beef: return "Beef"
        case .chicken: return "Chicken"
        case .seafood: return "Seafood"
        case .pork: return "Pork"
        case .lamb: return "Lamb"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        }
    }
    
    var icon: String {
        switch self {
        case .beef: return "Steak"
        case .chicken: return "Chicken"
        case .seafood: return "Seafood"
        case .pork: return "Pig"
        case .lamb: return "Lamb"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        }
    }
    
    var subtitle: String {
        switch self {
        case .beef: return "Steaks, burgers, roasts"
        case .chicken: return "Breasts, thighs, tenders"
        case .seafood: return "Fish, shrimp, shellfish"
        case .pork: return "Chops, sausage, bacon"
        case .lamb: return "Chops, roasts, ground"
        case .vegetarian: return "Eggs, dairy, no meat"
        case .vegan: return "Fully plant-based"
        }
    }
    
    var iconSystemName: String {
        switch self {
        case .beef: return "fork.knife"
        case .chicken: return "bird.fill"
        case .seafood: return "fish.fill"
        case .pork: return "flame.fill"
        case .lamb: return "fork.knife"
        case .vegetarian: return "leaf.circle.fill"
        case .vegan: return "leaf.fill"
        }
    }
}

enum Cuisine: String, CaseIterable, Identifiable, Codable {
    case italian
    case mexican
    case asian
    case mediterranean
    case american
    case indian
    case french
    case other
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .italian: return "Italian"
        case .mexican: return "Mexican"
        case .asian: return "Asian"
        case .mediterranean: return "Mediterranean"
        case .american: return "American"
        case .indian: return "Indian"
        case .french: return "French"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .italian: return "🍝"
        case .mexican: return "🌮"
        case .asian: return "🥢"
        case .mediterranean: return "🫒"
        case .american: return "🍔"
        case .indian: return "🍛"
        case .french: return "🥐"
        case .other: return "🍽️"
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

// MARK: - Smart Ingredient Parsing

enum IngredientCategory: String, CaseIterable {
    case protein = "🥩 Proteins"
    case produce = "🥬 Produce"
    case dairy = "🧀 Dairy & Eggs"
    case spices = "🌶️ Spices & Seasonings"
    case pantry = "🫙 Pantry"
    case other = "📦 Other"
    
    var sortOrder: Int {
        switch self {
        case .protein: return 0
        case .produce: return 1
        case .dairy: return 2
        case .spices: return 3
        case .pantry: return 4
        case .other: return 5
        }
    }
}

struct ParsedIngredient: Identifiable, Hashable {
    let id = UUID()
    let originalText: String
    let quantity: Double?
    let unit: String?
    let name: String
    let preparation: String?
    let category: IngredientCategory
    
    var displayText: String {
        var parts: [String] = []
        if let qty = quantity {
            parts.append(formatQuantity(qty))
        }
        if let unit = unit {
            parts.append(unit)
        }
        parts.append(name)
        return parts.joined(separator: " ")
    }
    
    var displayTextWithPrep: String {
        if let prep = preparation, !prep.isEmpty {
            return "\(displayText), \(prep)"
        }
        return displayText
    }
    
    private func formatQuantity(_ qty: Double) -> String {
        // Handle common fractions nicely
        let fractions: [(value: Double, display: String)] = [
            (0.125, "⅛"), (0.25, "¼"), (0.333, "⅓"), (0.5, "½"),
            (0.667, "⅔"), (0.75, "¾")
        ]
        
        let whole = Int(qty)
        let remainder = qty - Double(whole)
        
        // Check if remainder matches a fraction
        for (value, display) in fractions {
            if abs(remainder - value) < 0.05 {
                if whole > 0 {
                    return "\(whole)\(display)"
                } else {
                    return display
                }
            }
        }
        
        // If it's a whole number, return as int
        if abs(qty - Double(Int(qty))) < 0.01 {
            return "\(Int(qty))"
        }
        
        // Otherwise return with one decimal
        return String(format: "%.1f", qty)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ParsedIngredient, rhs: ParsedIngredient) -> Bool {
        lhs.id == rhs.id
    }
}

struct IngredientParser {
    
    // Common unit variations mapped to standard form
    static let unitNormalization: [String: String] = [
        "tbsp": "tbsp", "tablespoon": "tbsp", "tablespoons": "tbsp", "tbs": "tbsp",
        "tsp": "tsp", "teaspoon": "tsp", "teaspoons": "tsp",
        "cup": "cup", "cups": "cup",
        "oz": "oz", "ounce": "oz", "ounces": "oz",
        "lb": "lb", "lbs": "lb", "pound": "lb", "pounds": "lb",
        "clove": "cloves", "cloves": "cloves",
        "can": "can", "cans": "can",
        "bunch": "bunch", "bunches": "bunch",
        "slice": "slices", "slices": "slices",
        "piece": "pieces", "pieces": "pieces",
        "head": "head", "heads": "head",
        "sprig": "sprigs", "sprigs": "sprigs",
        "inch": "inch", "inches": "inch",
        "pinch": "pinch", "pinches": "pinch",
        "dash": "dash", "dashes": "dash",
        "pkg": "pkg", "package": "pkg", "packages": "pkg",
        "jar": "jar", "jars": "jar",
        "bottle": "bottle", "bottles": "bottle"
    ]
    
    // Fraction strings to decimal
    static let fractionMap: [String: Double] = [
        "½": 0.5, "1/2": 0.5,
        "¼": 0.25, "1/4": 0.25,
        "¾": 0.75, "3/4": 0.75,
        "⅓": 0.333, "1/3": 0.333,
        "⅔": 0.667, "2/3": 0.667,
        "⅛": 0.125, "1/8": 0.125,
        "⅜": 0.375, "3/8": 0.375,
        "⅝": 0.625, "5/8": 0.625,
        "⅞": 0.875, "7/8": 0.875
    ]
    
    // Preparation words to identify and extract
    static let preparationWords = Set([
        "minced", "diced", "sliced", "chopped", "cubed", "grated",
        "shredded", "crushed", "julienned", "thinly sliced", "finely chopped",
        "roughly chopped", "peeled", "deveined", "trimmed", "drained",
        "rinsed", "halved", "quartered", "mashed", "melted", "softened",
        "room temperature", "cold", "warm", "hot", "toasted", "packed"
    ])
    
    static func parse(_ ingredient: String) -> ParsedIngredient {
        var remaining = ingredient.trimmingCharacters(in: .whitespaces)
        var quantity: Double? = nil
        var unit: String? = nil
        var preparation: String? = nil
        
        // 1. Extract quantity
        (quantity, remaining) = extractQuantity(from: remaining)
        
        // 2. Extract unit
        (unit, remaining) = extractUnit(from: remaining)
        
        // 3. Extract preparation (after comma or in parentheses)
        (preparation, remaining) = extractPreparation(from: remaining)
        
        // 4. Clean up the ingredient name
        let name = cleanIngredientName(remaining)
        
        // 5. Categorize
        let category = categorize(name)
        
        return ParsedIngredient(
            originalText: ingredient,
            quantity: quantity,
            unit: unit,
            name: name,
            preparation: preparation,
            category: category
        )
    }
    
    private static func extractQuantity(from text: String) -> (Double?, String) {
        var remaining = text
        var total: Double = 0
        var foundNumber = false
        
        // First, try to match a number at the start
        // Pattern handles: "2", "1/2", "1 1/2", "1½", "½"
        
        // Check for unicode fraction at start
        for (frac, value) in fractionMap where frac.count == 1 {
            if remaining.hasPrefix(frac) {
                total += value
                foundNumber = true
                remaining = String(remaining.dropFirst()).trimmingCharacters(in: .whitespaces)
                return (total, remaining)
            }
        }
        
        // Try to match a whole number first
        var numberStr = ""
        var idx = remaining.startIndex
        while idx < remaining.endIndex && (remaining[idx].isNumber || remaining[idx] == "-") {
            // Handle ranges like "2-3" - take the first number
            if remaining[idx] == "-" && !numberStr.isEmpty {
                break
            }
            if remaining[idx].isNumber {
                numberStr.append(remaining[idx])
            }
            idx = remaining.index(after: idx)
        }
        
        if !numberStr.isEmpty, let wholeNum = Double(numberStr) {
            total += wholeNum
            foundNumber = true
            remaining = String(remaining[idx...]).trimmingCharacters(in: .whitespaces)
        }
        
        // Check for fraction after whole number
        // Could be unicode fraction or "1/2" style
        for (frac, value) in fractionMap {
            if remaining.hasPrefix(frac) {
                total += value
                foundNumber = true
                remaining = String(remaining.dropFirst(frac.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        return (foundNumber ? total : nil, remaining)
    }
    
    private static func extractUnit(from text: String) -> (String?, String) {
        let words = text.split(separator: " ", maxSplits: 1)
        guard let firstWord = words.first else { return (nil, text) }
        
        // Clean up the potential unit (remove parentheses, etc.)
        var potentialUnit = String(firstWord).lowercased()
        potentialUnit = potentialUnit.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        
        // Check if it matches a known unit
        if let normalized = unitNormalization[potentialUnit] {
            let remaining = words.count > 1 ? String(words[1]) : ""
            return (normalized, remaining.trimmingCharacters(in: .whitespaces))
        }
        
        // Check for parenthetical unit like "(14 oz)"
        if text.hasPrefix("(") {
            if let closeIdx = text.firstIndex(of: ")") {
                let inside = String(text[text.index(after: text.startIndex)..<closeIdx])
                // Try to parse as quantity + unit
                let (qty, unitText) = extractQuantity(from: inside)
                if qty != nil {
                    let unitWords = unitText.split(separator: " ")
                    if let firstUnitWord = unitWords.first {
                        let unitStr = String(firstUnitWord).lowercased()
                        if let normalized = unitNormalization[unitStr] {
                            let afterParen = String(text[text.index(after: closeIdx)...])
                                .trimmingCharacters(in: .whitespaces)
                            return (normalized, afterParen)
                        }
                    }
                }
            }
        }
        
        return (nil, text)
    }
    
    private static func extractPreparation(from text: String) -> (String?, String) {
        var name = text
        var preps: [String] = []
        
        // Check for comma-separated preparation
        if let commaIndex = text.firstIndex(of: ",") {
            let beforeComma = String(text[..<commaIndex]).trimmingCharacters(in: .whitespaces)
            let afterComma = String(text[text.index(after: commaIndex)...]).trimmingCharacters(in: .whitespaces)
            
            // Check if after-comma contains preparation words
            let afterLower = afterComma.lowercased()
            for prep in preparationWords {
                if afterLower.contains(prep) {
                    preps.append(afterComma)
                    name = beforeComma
                    break
                }
            }
        }
        
        // Check for parenthetical info that might be prep
        if let openParen = name.firstIndex(of: "("),
           let closeParen = name.firstIndex(of: ")") {
            let inside = String(name[name.index(after: openParen)..<closeParen])
            let insideLower = inside.lowercased()
            
            // If it's prep info, extract it
            for prep in preparationWords {
                if insideLower.contains(prep) {
                    preps.append(inside)
                    var newName = name
                    newName.removeSubrange(openParen...closeParen)
                    name = newName.trimmingCharacters(in: .whitespaces)
                    break
                }
            }
        }
        
        let finalPrep = preps.isEmpty ? nil : preps.joined(separator: ", ")
        return (finalPrep, name)
    }
    
    private static func cleanIngredientName(_ text: String) -> String {
        var name = text
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        
        // Remove leading articles
        let articles = ["a ", "an ", "the "]
        for article in articles {
            if name.lowercased().hasPrefix(article) {
                name = String(name.dropFirst(article.count))
            }
        }
        
        // Capitalize first letter of each word
        name = name.split(separator: " ")
            .map { word in
                let lower = word.lowercased()
                // Keep small words lowercase unless they're the first word
                if ["and", "or", "of", "with", "for", "&"].contains(lower) {
                    return lower
                }
                return word.prefix(1).uppercased() + word.dropFirst().lowercased()
            }
            .joined(separator: " ")
        
        return name
    }
    
    private static func categorize(_ name: String) -> IngredientCategory {
        let lower = name.lowercased()
        
        // Category keywords - order matters for ambiguous items
        let categoryKeywords: [(IngredientCategory, [String])] = [
            (.protein, [
                "chicken", "beef", "pork", "salmon", "fish", "shrimp", "tofu",
                "sausage", "steak", "ground", "turkey", "lamb", "bacon", "ham",
                "prosciutto", "pancetta", "tuna", "cod", "tilapia", "crab",
                "lobster", "scallop", "mussel", "clam", "duck", "venison",
                "brisket", "ribs", "flank", "sirloin", "tenderloin", "thigh",
                "breast", "drumstick", "wing"
            ]),
            (.produce, [
                "pepper", "onion", "garlic", "tomato", "spinach", "broccoli",
                "carrot", "cucumber", "lettuce", "avocado", "lemon", "lime",
                "mushroom", "potato", "zucchini", "cabbage", "asparagus",
                "eggplant", "celery", "kale", "arugula", "scallion", "shallot",
                "sweet potato", "squash", "corn", "pea", "bean sprout",
                "green onion", "jalapeño", "mango", "orange", "apple", "banana",
                "berry", "grape", "melon", "pineapple", "grapefruit", "peach",
                "pear", "plum", "cherry", "radish", "beet", "turnip", "leek",
                "fennel", "artichoke", "bok choy", "brussels", "cauliflower",
                "snap pea", "snow pea", "edamame", "bell pepper", "serrano",
                "habanero", "poblano", "chile", "chili pepper"
            ]),
            (.dairy, [
                "cheese", "cream", "milk", "yogurt", "butter", "egg",
                "sour cream", "ricotta", "mozzarella", "parmesan", "feta",
                "cheddar", "gouda", "brie", "gruyere", "mascarpone",
                "cream cheese", "cottage cheese", "half and half", "whipping"
            ]),
            (.spices, [
                "cumin", "paprika", "oregano", "thyme", "rosemary", "basil",
                "cilantro", "parsley", "ginger", "cinnamon", "nutmeg", "cayenne",
                "chili powder", "garam masala", "turmeric", "curry powder",
                "coriander", "cardamom", "cloves", "allspice", "bay leaf",
                "dill", "tarragon", "sage", "mint", "chive", "marjoram",
                "italian seasoning", "herbs de provence", "five spice",
                "old bay", "cajun", "taco seasoning", "ranch seasoning",
                "garlic powder", "onion powder", "smoked paprika", "sumac",
                "za'atar", "ras el hanout", "berbere", "harissa", "sriracha",
                "salt", "pepper", "seasoning", "spice", "extract", "vanilla"
            ]),
            (.pantry, [
                "oil", "olive oil", "vegetable oil", "sesame oil", "coconut oil",
                "sauce", "soy sauce", "fish sauce", "worcestershire", "hot sauce",
                "flour", "sugar", "brown sugar", "powdered sugar", "honey", "maple",
                "broth", "stock", "chicken broth", "beef broth", "vegetable broth",
                "pasta", "spaghetti", "penne", "fettuccine", "linguine", "orzo",
                "rice", "jasmine rice", "basmati", "brown rice", "wild rice",
                "noodle", "ramen", "udon", "rice noodle", "egg noodle",
                "tortilla", "bread", "pita", "naan", "baguette", "roll",
                "vinegar", "balsamic", "red wine vinegar", "rice vinegar",
                "peanut butter", "tahini", "coconut milk", "coconut cream",
                "beans", "black beans", "kidney beans", "chickpea", "lentil",
                "quinoa", "couscous", "barley", "farro", "bulgur",
                "panko", "breadcrumb", "cornstarch", "baking powder", "baking soda",
                "yeast", "gelatin", "cocoa", "chocolate", "chip",
                "tomato paste", "tomato sauce", "crushed tomatoes", "diced tomatoes",
                "ketchup", "mustard", "mayonnaise", "relish",
                "wine", "sherry", "mirin", "sake", "marsala",
                "capers", "olives", "sun-dried", "artichoke hearts",
                "nuts", "almond", "walnut", "pecan", "cashew", "pistachio", "peanut",
                "seeds", "sesame", "sunflower", "pumpkin seeds", "chia", "flax"
            ])
        ]
        
        for (category, keywords) in categoryKeywords {
            if keywords.contains(where: { lower.contains($0) }) {
                return category
            }
        }
        
        return .other
    }
}

struct ShoppingListAggregator {
    
    /// Combines ingredients from multiple recipes, aggregating quantities for same ingredients
    static func aggregate(recipes: [Recipe]) -> [(category: IngredientCategory, items: [ParsedIngredient])] {
        // Parse all ingredients
        let parsed = recipes.flatMap { $0.ingredients }.map { IngredientParser.parse($0) }
        
        // Group by normalized name + unit
        var grouped: [String: [ParsedIngredient]] = [:]
        for ingredient in parsed {
            // Create a key that groups similar ingredients
            let key = "\(ingredient.name.lowercased())|\(ingredient.unit ?? "whole")"
            grouped[key, default: []].append(ingredient)
        }
        
        // Combine quantities for same ingredients
        var combined: [ParsedIngredient] = []
        for (_, ingredients) in grouped {
            if ingredients.count == 1 {
                combined.append(ingredients[0])
            } else {
                // Sum quantities if all have quantities
                let quantities = ingredients.compactMap { $0.quantity }
                let totalQty: Double? = quantities.isEmpty ? nil : quantities.reduce(0, +)
                
                // Merge preparations (unique only)
                let preps = Set(ingredients.compactMap { $0.preparation })
                let mergedPrep = preps.isEmpty ? nil : preps.joined(separator: "; ")
                
                let first = ingredients[0]
                combined.append(ParsedIngredient(
                    originalText: first.originalText,
                    quantity: totalQty,
                    unit: first.unit,
                    name: first.name,
                    preparation: mergedPrep,
                    category: first.category
                ))
            }
        }
        
        // Group by category
        var byCategory: [IngredientCategory: [ParsedIngredient]] = [:]
        for ingredient in combined {
            byCategory[ingredient.category, default: []].append(ingredient)
        }
        
        // Sort each category alphabetically by name
        for category in byCategory.keys {
            byCategory[category]?.sort { $0.name.lowercased() < $1.name.lowercased() }
        }
        
        // Return sorted by category order
        return IngredientCategory.allCases
            .compactMap { category in
                guard let items = byCategory[category], !items.isEmpty else { return nil }
                return (category: category, items: items)
            }
    }
}

private enum PersistenceKeys {
    static let userPreferences = "enplace_userPreferences"
    static let likedRecipeNames = "enplace_likedRecipeNames"
    static let savedUserId = "enplace_savedUserId"
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
    
    static func saveUserId(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: PersistenceKeys.savedUserId)
    }
    
    static func loadUserId() -> String? {
        UserDefaults.standard.string(forKey: PersistenceKeys.savedUserId)
    }
    
    static func clearAllData() {
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.userPreferences)
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.likedRecipeNames)
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.savedUserId)
    }
}

// MARK: - ViewModel

@MainActor
final class RecipeSwipeViewModel: ObservableObject {
    @Published private(set) var recipes: [Recipe] = []
    @Published private(set) var likedRecipes: [Recipe] = []
    @Published private(set) var matchedRecipes: [Recipe] = []  // Recipes both chefs liked
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var isLoadingMore: Bool = false
    @Published private(set) var hasMoreRecipes: Bool = true
    private var useFirestore: Bool = false  // Internal - users don't need to know

    // UI Filters (optional, not from preferences)
    @Published var filterCookingFor: String? = nil  // nil = any, "couple", or "family"
    @Published var filterTimeMax: Int? = nil  // nil = any, or 30
    @Published var filterChefMax: Int? = nil  // nil = any, or 1, 2, 3

    // All recipes (local cache for lookups)
    private(set) var allRecipes: [Recipe] = []
    private var basePreferences: UserPreferences?
    
    // Firestore pagination state
    private var lastDocument: Any? = nil  // DocumentSnapshot
    private let batchSize = 20
    private var loadedRecipeIds: Set<String> = []  // Track loaded recipes to avoid duplicates

    init() {
        // Start with local JSON as immediate fallback
        self.allRecipes = RecipeService.loadRecipes()
        self.recipes = allRecipes
        
        let likedNames = PersistenceManager.loadLikedRecipeNames()
        self.likedRecipes = allRecipes.filter { likedNames.contains($0.name) }
        
        // Load matches from Firebase if available
        updateMatchesFromFirebase(matchedNames: FirebaseService.shared.matchedRecipeNames)
        
        // Check if Firestore has recipes and switch to it
        Task {
            await checkAndSwitchToFirestore()
        }
    }
    
    // MARK: - Firestore Integration
    
    /// Check if Firestore has recipes and switch data source
    private func checkAndSwitchToFirestore() async {
        let hasFirestoreRecipes = await FirebaseService.shared.hasRecipesInFirestore()
        
        if hasFirestoreRecipes {
            print("🔥 Firestore recipes available - switching to Firestore")
            useFirestore = true
            
            // Sync any new recipes from local JSON (runs in background)
            Task {
                await RecipeService.syncNewRecipesToFirestore()
            }
            
            // Check if images need migration (runs in background, doesn't block)
            Task {
                let hasImages = await FirebaseService.shared.hasImagesInStorage()
                if !hasImages {
                    print("📸 No images in storage - migrating images...")
                    await RecipeService.migrateImagesToStorage()
                }
            }
            
            await loadInitialRecipes()
        } else {
            // Auto-migrate local recipes to Firestore (one-time setup)
            print("📤 Firestore empty - auto-migrating local recipes...")
            await RecipeService.migrateRecipesToFirestore()
            
            // Now check again and switch
            let migrated = await FirebaseService.shared.hasRecipesInFirestore()
            if migrated {
                print("✅ Recipe migration complete - switching to Firestore")
                useFirestore = true
                
                // Migrate images in background (doesn't block app)
                Task {
                    print("📸 Migrating images to storage...")
                    await RecipeService.migrateImagesToStorage()
                }
                
                await loadInitialRecipes()
            } else {
                print("📁 Migration failed - using local JSON")
                useFirestore = false
            }
        }
    }
    
    /// Load initial batch of recipes from Firestore
    func loadInitialRecipes() async {
        guard useFirestore else { return }
        
        isLoadingMore = true
        lastDocument = nil
        loadedRecipeIds.removeAll()
        
        do {
            let result = try await FirebaseService.shared.fetchRecipes(
                limit: batchSize,
                startAfter: nil,
                cuisine: nil,
                maxCookTime: filterTimeMax,
                chefLevel: chefLevelString(filterChefMax),
                isForFamily: isForFamilyFilter(filterCookingFor)
            )
            
            let newRecipes = RecipeService.convertFromFirestoreRecipes(result.recipes)
            
            // Update tracking
            for recipe in newRecipes {
                loadedRecipeIds.insert(recipe.name)
            }
            
            self.recipes = newRecipes
            self.allRecipes = newRecipes  // For lookups
            self.lastDocument = result.lastDocument
            self.hasMoreRecipes = result.recipes.count == batchSize
            self.currentIndex = 0
            
            print("📚 Loaded initial \(newRecipes.count) recipes from Firestore")
        } catch {
            print("❌ Error loading from Firestore: \(error)")
            // Fallback to local
            useFirestore = false
            self.recipes = RecipeService.loadRecipes()
        }
        
        isLoadingMore = false
    }
    
    /// Load more recipes when user approaches end of current batch
    func loadMoreRecipesIfNeeded() async {
        guard useFirestore,
              hasMoreRecipes,
              !isLoadingMore,
              currentIndex >= recipes.count - 5 else { return }
        
        isLoadingMore = true
        
        do {
            // Import Firestore to cast lastDocument properly
            let result = try await FirebaseService.shared.fetchRecipes(
                limit: batchSize,
                startAfter: lastDocument as? FirebaseFirestore.DocumentSnapshot,
                cuisine: nil,
                maxCookTime: filterTimeMax,
                chefLevel: chefLevelString(filterChefMax),
                isForFamily: isForFamilyFilter(filterCookingFor)
            )
            
            let newRecipes = RecipeService.convertFromFirestoreRecipes(result.recipes)
            
            // Filter out duplicates
            let uniqueRecipes = newRecipes.filter { !loadedRecipeIds.contains($0.name) }
            
            // Update tracking
            for recipe in uniqueRecipes {
                loadedRecipeIds.insert(recipe.name)
            }
            
            self.recipes.append(contentsOf: uniqueRecipes)
            self.allRecipes.append(contentsOf: uniqueRecipes)
            self.lastDocument = result.lastDocument
            self.hasMoreRecipes = result.recipes.count == batchSize
            
            print("📚 Loaded \(uniqueRecipes.count) more recipes (total: \(recipes.count))")
        } catch {
            print("❌ Error loading more recipes: \(error)")
        }
        
        isLoadingMore = false
    }
    
    // Helper to convert filter to Firestore query format
    private func chefLevelString(_ maxChef: Int?) -> String? {
        guard let max = maxChef else { return nil }
        switch max {
        case 1: return "lineCook"
        case 2: return "sousChef"
        default: return nil
        }
    }
    
    private func isForFamilyFilter(_ cookingFor: String?) -> Bool? {
        guard let cf = cookingFor else { return nil }
        return cf == "family"
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
            
            // Pre-fetch more recipes when approaching end
            if useFirestore {
                Task {
                    await loadMoreRecipesIfNeeded()
                }
            }
        }
    }
    
    /// Update matched recipes from Firebase
    func updateMatchesFromFirebase(matchedNames: [String]) {
        matchedRecipes = allRecipes.filter { matchedNames.contains($0.name) }
    }
    
    /// Update liked recipes from Firebase (for syncing)
    func updateLikesFromFirebase(likedNames: [String]) {
        let firebaseLikes = allRecipes.filter { likedNames.contains($0.name) }
        // Merge with existing local likes (don't lose any)
        for recipe in firebaseLikes {
            if !likedRecipes.contains(recipe) {
                likedRecipes.append(recipe)
            }
        }
        // Save merged likes to local storage
        PersistenceManager.saveLikedRecipes(likedRecipes)
    }
    
    /// Clear all likes and matches (for new user)
    func clearAllLikesAndMatches() {
        likedRecipes = []
        matchedRecipes = []
        currentIndex = 0
        PersistenceManager.saveLikedRecipes([])
        print("🗑️ Cleared all local likes and matches")
    }

    func applyFilters(_ preferences: UserPreferences) {
        self.basePreferences = preferences
        reapplyAllFilters()
    }
    
    func reapplyAllFilters() {
        // If using Firestore, reload with filters
        if useFirestore {
            Task {
                await loadInitialRecipes()
            }
            return
        }
        
        // Local filtering for JSON-based recipes
        var filtered = allRecipes

        // Food preferences (from onboarding)
        if let preferences = basePreferences, !preferences.foodPreferences.isEmpty {
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
                    case .seafood:
                        if recipe.foodTags.contains(.seafood) { return true }
                    case .pork:
                        if recipe.foodTags.contains(.pork) { return true }
                    case .lamb:
                        if recipe.foodTags.contains(.lamb) { return true }
                    }
                }
                return false
            }
        }

        // Gluten-free restriction (from onboarding)
        if let preferences = basePreferences, preferences.isGlutenFree {
            filtered = filtered.filter { recipe in
                recipe.dietTags.contains(.glutenFree)
            }
        }

        // UI Filters (from Discover view)
        
        // Cooking For filter (couple or family)
        if let cookingFor = filterCookingFor {
            if cookingFor == "family" {
                filtered = filtered.filter { $0.isForFamily }
            } else if cookingFor == "couple" {
                filtered = filtered.filter { !$0.isForFamily }
            }
        }
        
        // Time filter
        if let maxTime = filterTimeMax {
            filtered = filtered.filter { $0.cookTimeMinutes <= maxTime }
        }
        
        // Chef level filter
        if let maxChef = filterChefMax {
        filtered = filtered.filter { recipe in
                let recipeLevel = recipe.chefLevels.first.map { level -> Int in
                    switch level {
                    case .lineCook: return 1
                    case .sousChef: return 2
                    case .executiveChef: return 3
                    }
                } ?? 1
                return recipeLevel <= maxChef
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
    @State private var showWelcome = true
    @State private var hasAcknowledgedInviteCode = false
    @State private var hasManuallyCompletedOnboarding = false
    
    // Computed property: onboarding is complete ONLY if:
    // 1. User manually completed it this session, OR
    // 2. Saved preferences exist AND the saved user ID matches the current Firebase user
    private var hasCompletedOnboarding: Bool {
        if hasManuallyCompletedOnboarding {
            return true
        }
        
        // Check if we have saved preferences
        guard PersistenceManager.loadPreferences() != nil else {
            return false
        }
        
        // Check if saved user ID matches current Firebase user
        guard let currentUserId = firebaseService.currentUser?.id,
              let savedUserId = PersistenceManager.loadUserId(),
              currentUserId == savedUserId else {
            return false
        }
        
        return true
    }

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
            } else if firebaseService.currentHousehold == nil {
                // Step 3a: No household yet - create or join one
                HouseholdSetupView(onContinue: {
                    withAnimation {
                        hasAcknowledgedInviteCode = true
                    }
                })
            } else if !hasCompletedOnboarding && !hasAcknowledgedInviteCode && firebaseService.currentUser?.isChefA == true {
                // Step 3b: Chef A just created household - show invite code
                // (Chef B skips this step and goes directly to onboarding)
                HouseholdSetupView(onContinue: {
                    withAnimation {
                        hasAcknowledgedInviteCode = true
                    }
                })
            } else if !hasCompletedOnboarding {
                // Step 4: Preferences onboarding (new users)
                OnboardingView(preferences: $preferences) {
                    hasManuallyCompletedOnboarding = true
                    // Save user ID along with preferences
                    if let userId = firebaseService.currentUser?.id {
                        PersistenceManager.saveUserId(userId)
                    }
                    PersistenceManager.savePreferences(preferences)
                    viewModel.applyFilters(preferences)
                }
            } else {
                // Step 5: Main app (returning users skip straight here)
                MainTabView(viewModel: viewModel, preferences: $preferences)
            }
        }
        .environmentObject(firebaseService)
        .onAppear {
            if hasCompletedOnboarding {
                viewModel.applyFilters(preferences)
            }
        }
        // When user ID changes, check if it's a different user and clear old data
        .onChange(of: firebaseService.currentUser?.id) { newUserId in
            guard let newUserId = newUserId else { return }
            
            let savedUserId = PersistenceManager.loadUserId()
            
            // If there's saved data for a DIFFERENT user, clear everything
            if let savedUserId = savedUserId, savedUserId != newUserId {
                print("🔄 New user detected (was: \(savedUserId), now: \(newUserId)) - clearing old data")
                PersistenceManager.clearAllData()
                viewModel.clearAllLikesAndMatches()
                preferences = UserPreferences()
                hasManuallyCompletedOnboarding = false
                hasAcknowledgedInviteCode = false
            } else if hasCompletedOnboarding {
                // Same user returning - load their preferences
                if let savedPrefs = PersistenceManager.loadPreferences() {
                    preferences = savedPrefs
                }
                viewModel.applyFilters(preferences)
            }
        }
        // Sync data from Firebase whenever household changes
        .onChange(of: firebaseService.currentHousehold) { newHousehold in
            if let household = newHousehold {
                // Sync matches
                viewModel.updateMatchesFromFirebase(matchedNames: household.matches)
                // Sync likes
                viewModel.updateLikesFromFirebase(likedNames: firebaseService.myLikes)
                print("🔄 Synced from Firebase - Matches: \(household.matches.count), Likes: \(firebaseService.myLikes.count)")
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

            MealPlanView(viewModel: viewModel)
                .tabItem {
                    Label("Meal Plan", systemImage: "calendar")
                }

            MyKitchenView(preferences: $preferences)
                .tabItem {
                    Label("My Kitchen", systemImage: "fork.knife")
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
    
    private var hasActiveFilters: Bool {
        viewModel.filterCookingFor != nil || viewModel.filterTimeMax != nil || viewModel.filterChefMax != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Filter bar
                filterBar

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

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Filter chips row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Cooking For filter
                    Menu {
                        Button("Any") {
                            viewModel.filterCookingFor = nil
                            viewModel.reapplyAllFilters()
                        }
                        Button {
                            viewModel.filterCookingFor = "couple"
                            viewModel.reapplyAllFilters()
                        } label: {
                            Label("Couple", systemImage: "person.2.fill")
                        }
                        Button {
                            viewModel.filterCookingFor = "family"
                            viewModel.reapplyAllFilters()
                        } label: {
                            Label("Family", systemImage: "person.3.fill")
                        }
                    } label: {
                        FilterChip(
                            label: "Cooking For",
                            icon: "person.2",
                            isActive: viewModel.filterCookingFor != nil
                        ) { }
                    }
                    
                    // Time filter - toggle for quick meals
                    FilterChip(
                        label: "< 30 min",
                        icon: "clock",
                        isActive: viewModel.filterTimeMax != nil
                    ) {
                        if viewModel.filterTimeMax == nil {
                            viewModel.filterTimeMax = 30
                        } else {
                            viewModel.filterTimeMax = nil
                        }
                        viewModel.reapplyAllFilters()
                    }
                    
                    // Difficulty filter
                    Menu {
                        Button("Any") {
                            viewModel.filterChefMax = nil
                            viewModel.reapplyAllFilters()
                        }
                        Button {
                            viewModel.filterChefMax = 1
                            viewModel.reapplyAllFilters()
                        } label: {
                            Label("Easy", systemImage: "flame.fill")
                        }
                        Button {
                            viewModel.filterChefMax = 2
                            viewModel.reapplyAllFilters()
                        } label: {
                            Label("Medium", systemImage: "flame.fill")
                        }
                        Button {
                            viewModel.filterChefMax = 3
                            viewModel.reapplyAllFilters()
                        } label: {
                            Label("Pro", systemImage: "flame.fill")
                        }
                    } label: {
                        FilterChip(
                            label: "Difficulty",
                            icon: "flame",
                            isActive: viewModel.filterChefMax != nil
                        ) { }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Clear button below filters (only shows when filters active)
            if hasActiveFilters {
                Button {
                    viewModel.filterCookingFor = nil
                    viewModel.filterTimeMax = nil
                    viewModel.filterChefMax = nil
                    viewModel.reapplyAllFilters()
                } label: {
                    Text("Clear filters")
                        .font(.caption)
                        .foregroundColor(AppTheme.primary)
                }
                .padding(.leading, 16)
            }
        }
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

// MARK: - Recipe Image (with URL support)

struct RecipeImage: View {
    let recipe: Recipe
    var contentMode: ContentMode = .fill
    
    var body: some View {
        Group {
            if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                // Load from cloud URL
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        // Loading state
                        ZStack {
                            gradientPlaceholder
                            ProgressView()
                                .tint(.white)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    case .failure:
                        // Failed to load from URL, try local
                        localOrPlaceholder
                    @unknown default:
                        localOrPlaceholder
                    }
                }
            } else {
                // No URL, use local asset
                localOrPlaceholder
            }
        }
    }
    
    @ViewBuilder
    private var localOrPlaceholder: some View {
        if let uiImage = UIImage(named: recipe.imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
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
            case .seafood: return [Color(red: 0.3, green: 0.5, blue: 0.7), Color(red: 0.4, green: 0.6, blue: 0.8)]
            case .pork: return [Color(red: 0.7, green: 0.45, blue: 0.4), Color(red: 0.85, green: 0.55, blue: 0.5)]
            case .vegetarian: return [Color(red: 0.4, green: 0.6, blue: 0.4), Color(red: 0.5, green: 0.7, blue: 0.5)]
            case .vegan: return [Color(red: 0.3, green: 0.55, blue: 0.35), Color(red: 0.4, green: 0.65, blue: 0.45)]
            case .lamb: return [Color(red: 0.55, green: 0.35, blue: 0.35), Color(red: 0.7, green: 0.45, blue: 0.45)]
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

// MARK: - Recipe Card

struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero Image
            ZStack(alignment: .bottomLeading) {
                // Image or gradient placeholder
                RecipeImage(recipe: recipe)
                
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
                
                // Bottom row - info badges
                HStack(spacing: 12) {
                    // Cook time
                    Label("\(recipe.cookTimeMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    // Family or Couple
                    Label(
                        recipe.isForFamily ? "Family" : "Couple",
                        systemImage: recipe.isForFamily ? "person.3.fill" : "person.2.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    // Difficulty - 3 knives (filled based on level)
                    ChefLevelKnives(chefLevels: recipe.chefLevels)
                }
            }
            .padding(16)
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? AppTheme.primary : AppTheme.cardBackground)
            .foregroundColor(isActive ? .white : AppTheme.textSecondary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isActive ? AppTheme.primary : AppTheme.textSecondary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Chef Level Knives

struct ChefLevelKnives: View {
    let chefLevels: [ChefLevel]
    
    // Convert chef levels to a 1-3 knife rating
    private var knifeRating: Int {
        guard let firstLevel = chefLevels.first else { return 1 }
        switch firstLevel {
        case .lineCook: return 1
        case .sousChef: return 2
        case .executiveChef: return 3
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { index in
                Image(systemName: index <= knifeRating ? "flame.fill" : "flame")
                    .font(.caption)
                    .foregroundStyle(index <= knifeRating ? AppTheme.secondary : AppTheme.textSecondary.opacity(0.3))
            }
        }
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
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Fill remaining slots with empty placeholders
                    if recipes.count < 4 {
                        ForEach(0..<(4 - recipes.count), id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(accentColor.opacity(0.1))
                                .aspectRatio(1, contentMode: .fit)
                                .frame(maxWidth: .infinity)
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
        RecipeImage(recipe: recipe)
            .frame(minWidth: 0, maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .clipped()
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
    
    // Filter state
    @State private var filterCookingFor: String? = nil
    @State private var filterTimeMax: Int? = nil
    @State private var filterChefMax: Int? = nil
    @State private var filterCuisine: Cuisine? = nil
    @State private var searchText: String = ""
    
    private var hasActiveFilters: Bool {
        filterCookingFor != nil || filterTimeMax != nil || filterChefMax != nil || filterCuisine != nil || !searchText.isEmpty
    }
    
    private var filteredRecipes: [Recipe] {
        var result = recipes
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Cooking For filter
        if let cookingFor = filterCookingFor {
            if cookingFor == "family" {
                result = result.filter { $0.isForFamily }
            } else if cookingFor == "couple" {
                result = result.filter { !$0.isForFamily }
            }
        }
        
        // Time filter
        if let maxTime = filterTimeMax {
            result = result.filter { $0.cookTimeMinutes <= maxTime }
        }
        
        // Chef level filter
        if let maxChef = filterChefMax {
            result = result.filter { recipe in
                let recipeLevel = recipe.chefLevels.first.map { level -> Int in
                    switch level {
                    case .lineCook: return 1
                    case .sousChef: return 2
                    case .executiveChef: return 3
                    }
                } ?? 1
                return recipeLevel <= maxChef
            }
        }
        
        // Cuisine filter
        if let cuisine = filterCuisine {
            result = result.filter { $0.cuisine == cuisine }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.textSecondary)
                TextField("Search recipes...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding(10)
            .background(AppTheme.cardBackground)
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            // Filter bar
            filterBar
            
            // Recipe list
            List {
                if filteredRecipes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle" : emptyIcon)
                            .font(.system(size: 50))
                            .foregroundStyle(isMatchList ? AppTheme.primary.opacity(0.5) : AppTheme.secondary.opacity(0.5))
                        Text(hasActiveFilters ? "No recipes match filters" : emptyTitle)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(hasActiveFilters ? "Try adjusting your filters" : emptyMessage)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        if hasActiveFilters {
                            Button("Clear Filters") {
                                clearFilters()
                            }
                            .font(.subheadline)
                            .foregroundColor(AppTheme.primary)
                            .padding(.top, 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            RecipeRowView(recipe: recipe, isMatch: isMatchList)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .background(AppTheme.background)
        .navigationTitle(title)
    }
    
    private var filterBar: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Cuisine filter
                        Menu {
                            Button("Any") {
                                filterCuisine = nil
                            }
                            ForEach(Cuisine.allCases) { cuisine in
                                Button {
                                    filterCuisine = cuisine
                                } label: {
                                    Text(cuisine.displayName)
                                }
                            }
                        } label: {
                            FilterChip(
                                label: filterCuisine?.displayName ?? "Cuisine",
                                icon: "globe",
                                isActive: filterCuisine != nil
                            ) { }
                        }
                        
                        // Cooking For filter
                        Menu {
                            Button("Any") {
                                filterCookingFor = nil
                            }
                            Button {
                                filterCookingFor = "couple"
                            } label: {
                                Label("Couple", systemImage: "person.2.fill")
                            }
                            Button {
                                filterCookingFor = "family"
                            } label: {
                                Label("Family", systemImage: "person.3.fill")
                            }
                        } label: {
                            FilterChip(
                                label: "Cooking For",
                                icon: "person.2",
                                isActive: filterCookingFor != nil
                            ) { }
                        }
                        
                        // Time filter
                        FilterChip(
                            label: "< 30 min",
                            icon: "clock",
                            isActive: filterTimeMax != nil
                        ) {
                            filterTimeMax = filterTimeMax == nil ? 30 : nil
                        }
                        
                        // Difficulty filter
                        Menu {
                            Button("Any") {
                                filterChefMax = nil
                            }
                            Button {
                                filterChefMax = 1
                            } label: {
                                Label("Easy", systemImage: "flame")
                            }
                            Button {
                                filterChefMax = 2
                            } label: {
                                Label("Medium", systemImage: "flame")
                            }
                            Button {
                                filterChefMax = 3
                            } label: {
                                Label("Pro", systemImage: "flame")
                            }
                        } label: {
                            FilterChip(
                                label: "Difficulty",
                                icon: "flame",
                                isActive: filterChefMax != nil
                            ) { }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(width: geometry.size.width)
                
                // Clear filters button
                if hasActiveFilters {
                    Button {
                        clearFilters()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                            Text("Clear filters")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(AppTheme.primary)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .frame(height: hasActiveFilters ? 80 : 50)
        .clipped()
    }
    
    private func clearFilters() {
        filterCookingFor = nil
        filterTimeMax = nil
        filterChefMax = nil
        filterCuisine = nil
        searchText = ""
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
                RecipeImage(recipe: recipe)
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
                    
                    Spacer()
                    
                    // Difficulty flames
                    ChefLevelKnives(chefLevels: recipe.chefLevels)
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
                    RecipeImage(recipe: recipe)
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

                HStack(spacing: 12) {
                    Label("\(recipe.cookTimeMinutes) min", systemImage: "clock")
                    Label(recipe.isForFamily ? "Family" : "Couple",
                          systemImage: recipe.isForFamily ? "person.3.fill" : "person.2.fill")
                    
                    Spacer()
                    
                    // Difficulty flames
                    ChefLevelKnives(chefLevels: recipe.chefLevels)
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
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .bold()
                            .frame(width: 28, alignment: .leading)
                        Text(step)
                            .fixedSize(horizontal: false, vertical: true)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Day Selection (for sheet timing fix)

struct DaySelection: Identifiable {
    let id = UUID()
    let day: String
}

// MARK: - Meal Plan View

struct MealPlanView: View {
    @ObservedObject var viewModel: RecipeSwipeViewModel
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var selectedDay: DaySelection? = nil
    @State private var showingShoppingList = false
    
    private let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    // Get all planned recipe names
    private var plannedRecipeNames: [String] {
        var names: [String] = []
        for day in daysOfWeek {
            names.append(contentsOf: firebaseService.mealPlan[day] ?? [])
        }
        return names
    }
    
    // Get all planned recipes
    private var plannedRecipes: [Recipe] {
        viewModel.allRecipes.filter { plannedRecipeNames.contains($0.name) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Week header with shopping button
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(AppTheme.primary)
                        Text("This Week")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        
                        // Shopping list button
                        Button {
                            showingShoppingList = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "cart.fill")
                                Text("Shop")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.primary)
                            .cornerRadius(16)
                        }
                        .disabled(plannedRecipeNames.isEmpty)
                        .opacity(plannedRecipeNames.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Days
                    ForEach(daysOfWeek, id: \.self) { day in
                        MealPlanDayCard(
                            day: day,
                            recipes: recipesForDay(day),
                            allRecipes: viewModel.allRecipes,
                            onAddTapped: {
                                selectedDay = DaySelection(day: day)
                            },
                            onRemoveRecipe: { recipeName in
                                Task {
                                    try? await firebaseService.removeRecipeFromMealPlan(day: day, recipeName: recipeName)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Meal Plan")
            .sheet(item: $selectedDay) { selection in
                AddMealSheet(
                    day: selection.day,
                    matchedRecipes: viewModel.matchedRecipes,
                    likedRecipes: viewModel.likedRecipes,
                    currentMealPlan: firebaseService.mealPlan,
                    onAddRecipe: { recipeName in
                        Task {
                            try? await firebaseService.addRecipeToMealPlan(day: selection.day, recipeName: recipeName)
                        }
                        selectedDay = nil
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingShoppingList) {
                ShoppingListView(recipes: plannedRecipes)
            }
        }
    }
    
    private func recipesForDay(_ day: String) -> [String] {
        firebaseService.mealPlan[day] ?? []
    }
}

// MARK: - Meal Plan Day Card

struct MealPlanDayCard: View {
    let day: String
    let recipes: [String]
    let allRecipes: [Recipe]
    let onAddTapped: () -> Void
    let onRemoveRecipe: (String) -> Void
    
    private var isToday: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date()) == day
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day header
            HStack {
                Text(day)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isToday ? AppTheme.primary : AppTheme.textPrimary)
                
                if isToday {
                    Text("Today")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppTheme.primary)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            
            // Recipes for the day
            if recipes.isEmpty {
                // Empty state - Add button
                Button(action: onAddTapped) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.primary.opacity(0.6))
                        Text("Add a meal")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                    )
                }
            } else {
                // Show planned recipes
                ForEach(recipes, id: \.self) { recipeName in
                    MealPlanRecipeRow(
                        recipeName: recipeName,
                        recipe: allRecipes.first { $0.name == recipeName },
                        onRemove: { onRemoveRecipe(recipeName) }
                    )
                }
                
                // Add more button
                Button(action: onAddTapped) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.caption)
                        Text("Add another")
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.primary)
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

// MARK: - Meal Plan Recipe Row

struct MealPlanRecipeRow: View {
    let recipeName: String
    let recipe: Recipe?
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Recipe thumbnail
            if let recipe = recipe, let uiImage = UIImage(named: recipe.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(AppTheme.primary.opacity(0.5))
                    )
            }
            
            // Recipe info
            VStack(alignment: .leading, spacing: 2) {
                Text(recipeName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                
                if let recipe = recipe {
                    Text("\(recipe.cookTimeMinutes) min")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.background)
        )
    }
}

// MARK: - Add Meal Sheet

struct AddMealSheet: View {
    let day: String
    let matchedRecipes: [Recipe]
    let likedRecipes: [Recipe]
    let currentMealPlan: [String: [String]]
    let onAddRecipe: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showLikedRecipes = false
    
    private var recipesToShow: [Recipe] {
        showLikedRecipes ? likedRecipes : matchedRecipes
    }
    
    // Get recipes already planned for this day
    private var plannedRecipeNames: [String] {
        currentMealPlan[day] ?? []
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Toggle between matches and my likes
                Picker("Recipe Source", selection: $showLikedRecipes) {
                    Text("Matches (\(matchedRecipes.count))").tag(false)
                    Text("My Likes (\(likedRecipes.count))").tag(true)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if recipesToShow.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: showLikedRecipes ? "hand.thumbsup.circle" : "heart.circle")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                        
                        Text(showLikedRecipes ? "No liked recipes yet!" : "No matches yet!")
                            .font(.headline)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text(showLikedRecipes 
                             ? "Swipe right on recipes in Discover to add them here"
                             : "Match with your partner to plan meals together")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else {
                    // Recipe list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(recipesToShow) { recipe in
                                let isPlanned = plannedRecipeNames.contains(recipe.name)
                                
                                Button {
                                    if !isPlanned {
                                        onAddRecipe(recipe.name)
                                    }
                                } label: {
                                    AddMealRecipeRow(recipe: recipe, isAlreadyPlanned: isPlanned)
                                }
                                .disabled(isPlanned)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Add to \(day)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Meal Recipe Row

struct AddMealRecipeRow: View {
    let recipe: Recipe
    let isAlreadyPlanned: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Recipe thumbnail
            if let uiImage = UIImage(named: recipe.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .cornerRadius(10)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(AppTheme.primary.opacity(0.5))
                    )
            }
            
            // Recipe info
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isAlreadyPlanned ? AppTheme.textSecondary : AppTheme.textPrimary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label("\(recipe.cookTimeMinutes) min", systemImage: "clock")
                    
                    if !recipe.dietTags.filter({ $0 != .none }).isEmpty {
                        Text(recipe.dietTags.filter { $0 != .none }.first?.displayName ?? "")
                    }
                }
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Status indicator
            if isAlreadyPlanned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.primary.opacity(0.5))
            } else {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(AppTheme.primary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isAlreadyPlanned ? AppTheme.background : AppTheme.cardBackground)
                .shadow(color: .black.opacity(isAlreadyPlanned ? 0 : 0.05), radius: 4, y: 2)
        )
        .opacity(isAlreadyPlanned ? 0.7 : 1)
    }
}

// MARK: - Shopping List View (Smart Parsing)

struct ShoppingListView: View {
    let recipes: [Recipe]
    @Environment(\.dismiss) private var dismiss
    @State private var checkedItems: Set<UUID> = []
    @State private var showingShareSheet = false
    
    // Smart aggregated ingredients using the parser
    private var aggregatedIngredients: [(category: IngredientCategory, items: [ParsedIngredient])] {
        ShoppingListAggregator.aggregate(recipes: recipes)
    }
    
    // Total item count
    private var totalItemCount: Int {
        aggregatedIngredients.reduce(0) { $0 + $1.items.count }
    }
    
    // Generate plain text list for sharing
    private var shoppingListText: String {
        var text = "🛒 Shopping List for \(recipes.count) recipe\(recipes.count == 1 ? "" : "s")\n"
        text += "Generated by EnPlace\n\n"
        
        for (category, items) in aggregatedIngredients {
            text += "\(category.rawValue)\n"
            for item in items {
                let check = checkedItems.contains(item.id) ? "✓" : "○"
                text += "  \(check) \(item.displayText)\n"
            }
            text += "\n"
        }
        
        return text
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Summary header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(recipes.count) recipe\(recipes.count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("\(totalItemCount) items")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        
                        Spacer()
                        
                        // Progress
                        let progress = Double(checkedItems.count) / Double(max(totalItemCount, 1))
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(checkedItems.count)/\(totalItemCount)")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            ProgressView(value: progress)
                                .frame(width: 80)
                                .tint(AppTheme.primary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.cardBackground)
                    )
                    
                    // Recipes included
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recipes")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recipes) { recipe in
                                    Text(recipe.name)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(AppTheme.primary.opacity(0.1))
                                        .foregroundColor(AppTheme.primary)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    // Categorized ingredients with smart aggregation
                    ForEach(aggregatedIngredients, id: \.category) { category, items in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.rawValue)
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            ForEach(items) { ingredient in
                                SmartShoppingListItemRow(
                                    ingredient: ingredient,
                                    isChecked: checkedItems.contains(ingredient.id),
                                    onToggle: {
                                        if checkedItems.contains(ingredient.id) {
                                            checkedItems.remove(ingredient.id)
                                        } else {
                                            checkedItems.insert(ingredient.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    
                    // Clear checked items button
                    if !checkedItems.isEmpty {
                        Button {
                            checkedItems.removeAll()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset All")
                            }
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            UIPasteboard.general.string = shoppingListText
                        } label: {
                            Label("Copy List", systemImage: "doc.on.doc")
                        }
                        
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share List", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [shoppingListText])
            }
        }
    }
}

// MARK: - Smart Shopping List Item Row

struct SmartShoppingListItemRow: View {
    let ingredient: ParsedIngredient
    let isChecked: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isChecked ? AppTheme.primary : AppTheme.textSecondary.opacity(0.5))
                    .font(.title3)
                
                // Ingredient text with quantity highlighting
                HStack(spacing: 4) {
                    // Quantity + Unit (if present)
                    if ingredient.quantity != nil || ingredient.unit != nil {
                        Text(quantityUnitText)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(isChecked ? AppTheme.textSecondary : AppTheme.primary)
                    }
                    
                    // Ingredient name
                    Text(ingredient.name)
                        .font(.subheadline)
                        .foregroundColor(isChecked ? AppTheme.textSecondary : AppTheme.textPrimary)
                }
                .strikethrough(isChecked, color: AppTheme.textSecondary)
                
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isChecked ? AppTheme.background : AppTheme.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var quantityUnitText: String {
        var parts: [String] = []
        if let qty = ingredient.quantity {
            parts.append(formatQuantity(qty))
        }
        if let unit = ingredient.unit {
            parts.append(unit)
        }
        return parts.joined(separator: " ")
    }
    
    private func formatQuantity(_ qty: Double) -> String {
        let fractions: [(value: Double, display: String)] = [
            (0.125, "⅛"), (0.25, "¼"), (0.333, "⅓"), (0.5, "½"),
            (0.667, "⅔"), (0.75, "¾")
        ]
        
        let whole = Int(qty)
        let remainder = qty - Double(whole)
        
        for (value, display) in fractions {
            if abs(remainder - value) < 0.05 {
                if whole > 0 {
                    return "\(whole)\(display)"
                } else {
                    return display
                }
            }
        }
        
        if abs(qty - Double(Int(qty))) < 0.01 {
            return "\(Int(qty))"
        }
        
        return String(format: "%.1f", qty)
    }
}

// MARK: - My Kitchen Screen

struct MyKitchenView: View {
    @Binding var preferences: UserPreferences
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var showingSignOutAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Kitchen Info Section
                Section {
                    if let household = firebaseService.currentHousehold {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(AppTheme.primary)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Kitchen Code")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(household.inviteCode)
                                    .font(.headline)
                                    .fontDesign(.monospaced)
                            }
                            Spacer()
                            Button {
                                UIPasteboard.general.string = household.inviteCode
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(AppTheme.primary)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Chefs in Kitchen")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                let memberCount = household.chefBId != nil ? 2 : 1
                                Text("\(memberCount) chef\(memberCount == 1 ? "" : "s")")
                                    .font(.headline)
                            }
                        }
                    }
                    
                    if let user = firebaseService.currentUser {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(AppTheme.primary)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Account")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(user.email)
                                    .font(.subheadline)
                            }
                        }
                    }
                } header: {
                    Text("My Kitchen")
                }
                
                // MARK: - Food Preferences
                Section("Food preferences") {
                    ForEach(FoodPreference.allCases) { food in
                        Toggle(food.displayName, isOn: binding(for: food))
                    }
                }
                
                Section("Dietary restrictions") {
                    Toggle("Gluten-free only", isOn: $preferences.isGlutenFree)
                }

                // MARK: - Account Actions
                Section {
                    Button(role: .destructive) {
                        showingSignOutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                    }
                }
            }
            .navigationTitle("My Kitchen")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    try? firebaseService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Single step - food preferences and dietary
                        OnboardingFoodPreferencesStep(
                            foodPreferences: $preferences.foodPreferences,
                            isGlutenFree: $preferences.isGlutenFree
                        )
                    
                    Spacer()
                    
                Button("Get Started") {
                                    onFinished()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.primary)
                }
                .padding()
            .navigationTitle("Food Preferences")
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



