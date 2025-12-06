//
//  recipeservice.swift
//  EnPlace2
//
//  Created by Sam Berenato on 12/6/25.
//

import Foundation

struct RecipeResponse: Codable {
    let recipes: [Recipe]
}

enum RecipeService {
    static func loadRecipes() -> [Recipe] {
        guard let url = Bundle.main.url(forResource: "recipes", withExtension: "json") else {
            print("❌ recipes.json not found in bundle")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(RecipeResponse.self, from: data)
            print("✅ Loaded \(response.recipes.count) recipes from JSON")
            return response.recipes
        } catch {
            print("❌ Error decoding recipes.json: \(error)")
            return []
        }
    }
}
