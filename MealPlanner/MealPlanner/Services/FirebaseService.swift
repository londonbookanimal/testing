import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage
import UIKit

// MARK: - FirebaseService
// Central service for all Firestore and Storage operations.

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

    // MARK: - Collection references

    private var familyCollection: CollectionReference {
        db.collection("family_members")
    }

    private var foodItemsCollection: CollectionReference {
        db.collection("food_items")
    }

    private var recipesCollection: CollectionReference {
        db.collection("recipes")
    }

    private var mealPlansCollection: CollectionReference {
        db.collection("meal_plans")
    }

    private var feedbackCollection: CollectionReference {
        db.collection("feedback")
    }

    // MARK: - Family Members

    func fetchFamilyMembers() async throws -> [FamilyMember] {
        let snapshot = try await familyCollection.order(by: "name").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FamilyMember.self) }
    }

    func saveFamilyMember(_ member: FamilyMember) async throws -> FamilyMember {
        if let id = member.id {
            try familyCollection.document(id).setData(from: member)
            return member
        } else {
            let ref = try familyCollection.addDocument(from: member)
            var saved = member
            saved.id = ref.documentID
            return saved
        }
    }

    func deleteFamilyMember(id: String) async throws {
        try await familyCollection.document(id).delete()
    }

    func updateMemberPreferences(memberId: String, preferences: FoodPreferences) async throws {
        let encoded = try Firestore.Encoder().encode(preferences)
        try await familyCollection.document(memberId).updateData([
            "preferences": encoded,
            "updatedAt": Timestamp(date: Date())
        ])
    }

    func addMealRating(memberId: String, rating: MealRating) async throws {
        let encoded = try Firestore.Encoder().encode(rating)
        try await familyCollection.document(memberId).updateData([
            "preferences.ratingHistory": FieldValue.arrayUnion([encoded]),
            "updatedAt": Timestamp(date: Date())
        ])
    }

    // MARK: - Food Items

    func fetchFoodItems(location: FoodLocation? = nil) async throws -> [FoodItem] {
        let query: Query
        if let location = location {
            query = foodItemsCollection
                .whereField("location", isEqualTo: location.rawValue)
        } else {
            query = foodItemsCollection
        }
        let snapshot = try await query.getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: FoodItem.self) }
            .sorted { $0.name < $1.name }
    }

    func saveFoodItem(_ item: FoodItem) async throws -> FoodItem {
        if let id = item.id {
            try foodItemsCollection.document(id).setData(from: item)
            return item
        } else {
            let ref = try foodItemsCollection.addDocument(from: item)
            var saved = item
            saved.id = ref.documentID
            return saved
        }
    }

    func deleteFoodItem(id: String) async throws {
        try await foodItemsCollection.document(id).delete()
    }

    func bulkSaveFoodItems(_ items: [FoodItem]) async throws {
        let batch = db.batch()
        for item in items {
            if let id = item.id {
                let ref = foodItemsCollection.document(id)
                try batch.setData(from: item, forDocument: ref)
            } else {
                let ref = foodItemsCollection.document()
                try batch.setData(from: item, forDocument: ref)
            }
        }
        try await batch.commit()
    }

    // MARK: - Recipes

    func fetchRecipes() async throws -> [Recipe] {
        let snapshot = try await recipesCollection
            .order(by: "averageRating", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Recipe.self) }
    }

    func saveRecipe(_ recipe: Recipe) async throws -> Recipe {
        if let id = recipe.id {
            try recipesCollection.document(id).setData(from: recipe)
            return recipe
        } else {
            let ref = try recipesCollection.addDocument(from: recipe)
            var saved = recipe
            saved.id = ref.documentID
            return saved
        }
    }

    func updateRecipeRating(recipeId: String, newRating: Double, ratingCount: Int) async throws {
        try await recipesCollection.document(recipeId).updateData([
            "averageRating": newRating,
            "ratingCount": ratingCount
        ])
    }

    // MARK: - Meal Plans

    func fetchMealPlans(from startDate: Date, to endDate: Date) async throws -> [MealPlan] {
        let snapshot = try await mealPlansCollection
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: MealPlan.self) }
            .sorted { $0.date < $1.date }
    }

    func saveMealPlan(_ plan: MealPlan) async throws -> MealPlan {
        if let id = plan.id {
            try mealPlansCollection.document(id).setData(from: plan)
            return plan
        } else {
            let ref = try mealPlansCollection.addDocument(from: plan)
            var saved = plan
            saved.id = ref.documentID
            return saved
        }
    }

    func markMealPlanCooked(id: String) async throws {
        try await mealPlansCollection.document(id).updateData([
            "status": MealPlanStatus.cooked.rawValue
        ])
    }

    // MARK: - Feedback

    func saveFeedback(_ feedback: PostMealFeedback) async throws {
        try feedbackCollection.addDocument(from: feedback)
    }

    // MARK: - Image Upload

    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw FirebaseServiceError.imageConversionFailed
        }
        let ref = storage.reference().child(path)
        _ = try await ref.putDataAsync(imageData)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    enum FirebaseServiceError: LocalizedError {
        case imageConversionFailed

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Failed to convert image for upload."
            }
        }
    }
}
