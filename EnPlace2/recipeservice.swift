//
//  recipeservice.swift
//  EnPlace2
//
//  Created by Sam Berenato on 12/6/25.
//

import Foundation
import UIKit

struct RecipeResponse: Codable {
    let recipes: [Recipe]
}

enum RecipeService {
    
    // MARK: - Load from Local JSON (fallback)
    
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
    
    // MARK: - Convert to Firestore Format
    
    /// Convert local Recipe to FirestoreRecipe for migration
    static func convertToFirestoreRecipes(_ recipes: [Recipe]) -> [FirestoreRecipe] {
        return recipes.map { recipe in
            // Determine primary chef level for filtering
            let primaryLevel: String
            if recipe.chefLevels.contains(.lineCook) {
                primaryLevel = "lineCook"
            } else if recipe.chefLevels.contains(.sousChef) {
                primaryLevel = "sousChef"
            } else {
                primaryLevel = "executiveChef"
            }
            
            return FirestoreRecipe(
                documentId: nil,
                id: recipe.name.lowercased().replacingOccurrences(of: " ", with: "-"),
                name: recipe.name,
                isForFamily: recipe.isForFamily,
                dietTags: recipe.dietTags.map { $0.rawValue },
                chefLevel: primaryLevel,
                chefLevels: recipe.chefLevels.map { $0.rawValue },
                cookTimeMinutes: recipe.cookTimeMinutes,
                description: recipe.description,
                ingredients: recipe.ingredients,
                steps: recipe.steps,
                foodTags: recipe.foodTags.map { $0.rawValue },
                imageName: recipe.imageName,
                cuisine: recipe.cuisine.rawValue,
                imageURL: nil  // Will be set during image migration
            )
        }
    }
    
    // MARK: - Convert from Firestore to Local Model
    
    /// Convert FirestoreRecipe to local Recipe model
    static func convertFromFirestoreRecipe(_ firestoreRecipe: FirestoreRecipe) -> Recipe? {
        // Map string values back to enums
        let dietTags = firestoreRecipe.dietTags.compactMap { DietTag(rawValue: $0) }
        let chefLevels = firestoreRecipe.chefLevels.compactMap { ChefLevel(rawValue: $0) }
        let foodTags = firestoreRecipe.foodTags.compactMap { FoodPreference(rawValue: $0) }
        let cuisine = Cuisine(rawValue: firestoreRecipe.cuisine) ?? .other
        
        return Recipe(
            id: UUID(),
            name: firestoreRecipe.name,
            isForFamily: firestoreRecipe.isForFamily,
            dietTags: dietTags,
            chefLevels: chefLevels,
            cookTimeMinutes: firestoreRecipe.cookTimeMinutes,
            description: firestoreRecipe.description,
            ingredients: firestoreRecipe.ingredients,
            steps: firestoreRecipe.steps,
            foodTags: foodTags,
            imageName: firestoreRecipe.imageName,
            cuisine: cuisine,
            imageURL: firestoreRecipe.imageURL
        )
    }
    
    /// Convert array of FirestoreRecipes to local Recipe models
    static func convertFromFirestoreRecipes(_ firestoreRecipes: [FirestoreRecipe]) -> [Recipe] {
        return firestoreRecipes.compactMap { convertFromFirestoreRecipe($0) }
    }
    
    // MARK: - Migration Helper
    
    /// Upload all local JSON recipes to Firestore
    static func migrateRecipesToFirestore() async {
        let localRecipes = loadRecipes()
        guard !localRecipes.isEmpty else {
            print("❌ No local recipes to migrate")
            return
        }
        
        let firestoreRecipes = convertToFirestoreRecipes(localRecipes)
        
        // Upload in batches of 20 (Firestore batch limit is 500, but smaller is safer)
        let batchSize = 20
        var uploaded = 0
        
        for startIndex in stride(from: 0, to: firestoreRecipes.count, by: batchSize) {
            let endIndex = min(startIndex + batchSize, firestoreRecipes.count)
            let batch = Array(firestoreRecipes[startIndex..<endIndex])
            
            do {
                try await FirebaseService.shared.uploadRecipesBatch(batch)
                uploaded += batch.count
                print("📤 Uploaded \(uploaded)/\(firestoreRecipes.count) recipes")
            } catch {
                print("❌ Error uploading batch: \(error)")
            }
        }
        
        print("✅ Migration complete: \(uploaded) recipes uploaded to Firestore")
    }
    
    // MARK: - Image Migration
    
    /// Upload all local recipe images to Firebase Storage
    static func migrateImagesToStorage() async {
        let localRecipes = loadRecipes()
        guard !localRecipes.isEmpty else {
            print("❌ No local recipes for image migration")
            return
        }
        
        var uploaded = 0
        var skipped = 0
        
        for recipe in localRecipes {
            // Check if this recipe already has an image URL
            let recipeId = recipe.name.lowercased().replacingOccurrences(of: " ", with: "-")
            let hasImage = await FirebaseService.shared.recipeHasImageURL(recipeId: recipeId)
            
            if hasImage {
                skipped += 1
                continue
            }
            
            // Try to load image from assets
            guard let uiImage = UIImage(named: recipe.imageName) else {
                print("⚠️ No image found for: \(recipe.imageName)")
                skipped += 1
                continue
            }
            
            // Compress to JPEG
            guard let imageData = uiImage.jpegData(compressionQuality: 0.8) else {
                print("⚠️ Could not compress image: \(recipe.imageName)")
                skipped += 1
                continue
            }
            
            do {
                // Upload to Firebase Storage
                let imageURL = try await FirebaseService.shared.uploadRecipeImage(
                    imageName: recipe.imageName,
                    imageData: imageData
                )
                
                // Update recipe document with image URL
                try await FirebaseService.shared.updateRecipeImageURL(
                    recipeId: recipeId,
                    imageURL: imageURL
                )
                
                uploaded += 1
                print("📸 Uploaded \(uploaded)/\(localRecipes.count - skipped): \(recipe.name)")
            } catch {
                print("❌ Error uploading image for \(recipe.name): \(error)")
            }
        }
        
        print("✅ Image migration complete: \(uploaded) uploaded, \(skipped) skipped")
    }
}
