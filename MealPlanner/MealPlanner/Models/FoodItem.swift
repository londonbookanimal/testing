import Foundation
import FirebaseFirestore

struct FoodItem: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var category: FoodCategory
    var quantity: Double
    var unit: String
    var location: FoodLocation
    var expiryDate: Date?
    var imageURL: String?
    var addedAt: Date

    init(id: String? = nil,
         name: String,
         category: FoodCategory = .other,
         quantity: Double = 1,
         unit: String = "unit",
         location: FoodLocation,
         expiryDate: Date? = nil,
         imageURL: String? = nil,
         addedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.location = location
        self.expiryDate = expiryDate
        self.imageURL = imageURL
        self.addedAt = addedAt
    }

    var isExpiringSoon: Bool {
        guard let expiry = expiryDate else { return false }
        let threeDays: TimeInterval = 3 * 24 * 60 * 60
        return expiry.timeIntervalSinceNow < threeDays && expiry.timeIntervalSinceNow > 0
    }

    var isExpired: Bool {
        guard let expiry = expiryDate else { return false }
        return expiry < Date()
    }
}

enum FoodCategory: String, Codable, CaseIterable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat & Seafood"
    case grains = "Grains & Pasta"
    case canned = "Canned Goods"
    case condiments = "Condiments & Sauces"
    case spices = "Spices & Seasonings"
    case frozen = "Frozen"
    case snacks = "Snacks"
    case beverages = "Beverages"
    case other = "Other"

    var emoji: String {
        switch self {
        case .produce:    return "🥦"
        case .dairy:      return "🧀"
        case .meat:       return "🥩"
        case .grains:     return "🌾"
        case .canned:     return "🥫"
        case .condiments: return "🫙"
        case .spices:     return "🌶️"
        case .frozen:     return "🧊"
        case .snacks:     return "🍿"
        case .beverages:  return "🥤"
        case .other:      return "📦"
        }
    }
}

enum FoodLocation: String, Codable, CaseIterable {
    case fridge = "Fridge"
    case pantry = "Pantry"
    case freezer = "Freezer"
}
