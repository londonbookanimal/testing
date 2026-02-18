import Foundation
import FirebaseFirestore

struct FamilyMember: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var age: Int
    var avatarEmoji: String
    var preferences: FoodPreferences
    var createdAt: Date
    var updatedAt: Date

    init(id: String? = nil,
         name: String,
         age: Int,
         avatarEmoji: String = "👤",
         preferences: FoodPreferences = FoodPreferences(),
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.age = age
        self.avatarEmoji = avatarEmoji
        self.preferences = preferences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct FoodPreferences: Codable {
    var likedIngredients: [String]
    var dislikedIngredients: [String]
    var likedCuisines: [String]
    var dislikedCuisines: [String]
    var dietaryRestrictions: [DietaryRestriction]
    var allergies: [String]
    var ratingHistory: [MealRating]

    init(likedIngredients: [String] = [],
         dislikedIngredients: [String] = [],
         likedCuisines: [String] = [],
         dislikedCuisines: [String] = [],
         dietaryRestrictions: [DietaryRestriction] = [],
         allergies: [String] = [],
         ratingHistory: [MealRating] = []) {
        self.likedIngredients = likedIngredients
        self.dislikedIngredients = dislikedIngredients
        self.likedCuisines = likedCuisines
        self.dislikedCuisines = dislikedCuisines
        self.dietaryRestrictions = dietaryRestrictions
        self.allergies = allergies
        self.ratingHistory = ratingHistory
    }
}

enum DietaryRestriction: String, Codable, CaseIterable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case kosher = "Kosher"
    case halal = "Halal"
    case none = "None"
}

struct MealRating: Codable, Identifiable {
    var id: String
    var recipeId: String
    var recipeName: String
    var rating: Int        // 1-5
    var comment: String
    var date: Date

    init(recipeId: String, recipeName: String, rating: Int, comment: String = "", date: Date = Date()) {
        self.id = UUID().uuidString
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.rating = rating
        self.comment = comment
        self.date = date
    }
}
