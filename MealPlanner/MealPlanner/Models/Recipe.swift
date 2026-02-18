import Foundation
import FirebaseFirestore

struct Recipe: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var cuisine: String
    var ingredients: [RecipeIngredient]
    var instructions: [String]
    var prepTimeMinutes: Int
    var cookTimeMinutes: Int
    var servings: Int
    var imageURL: String?
    var tags: [String]
    var averageRating: Double
    var ratingCount: Int
    var suitableForMembers: [String]   // FamilyMember IDs who can eat this
    var source: RecipeSource

    var totalTimeMinutes: Int { prepTimeMinutes + cookTimeMinutes }

    var formattedTotalTime: String {
        let hours = totalTimeMinutes / 60
        let minutes = totalTimeMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct RecipeIngredient: Codable, Identifiable {
    var id: String
    var name: String
    var quantity: Double
    var unit: String
    var isAvailable: Bool   // populated after checking pantry/fridge

    init(name: String, quantity: Double, unit: String) {
        self.id = UUID().uuidString
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.isAvailable = false
    }
}

enum RecipeSource: String, Codable {
    case aiGenerated = "AI Generated"
    case userAdded = "User Added"
    case external = "External"
}
