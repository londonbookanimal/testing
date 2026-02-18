import Foundation
import FirebaseFirestore

struct MealPlan: Identifiable, Codable {
    @DocumentID var id: String?
    var date: Date
    var dinnerRecipe: Recipe?
    var dinnerRecipeId: String?
    var status: MealPlanStatus
    var feedbackSubmitted: Bool
    var notes: String
    var createdAt: Date

    init(id: String? = nil,
         date: Date = Date(),
         dinnerRecipe: Recipe? = nil,
         dinnerRecipeId: String? = nil,
         status: MealPlanStatus = .planned,
         feedbackSubmitted: Bool = false,
         notes: String = "",
         createdAt: Date = Date()) {
        self.id = id
        self.date = date
        self.dinnerRecipe = dinnerRecipe
        self.dinnerRecipeId = dinnerRecipeId
        self.status = status
        self.feedbackSubmitted = feedbackSubmitted
        self.notes = notes
        self.createdAt = createdAt
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}

enum MealPlanStatus: String, Codable {
    case planned = "Planned"
    case cooked = "Cooked"
    case skipped = "Skipped"
}

struct PostMealFeedback: Identifiable, Codable {
    @DocumentID var id: String?
    var mealPlanId: String
    var recipeId: String
    var recipeName: String
    var memberRatings: [String: MealRating]   // keyed by FamilyMember ID
    var overallNotes: String
    var wouldMakeAgain: Bool
    var submittedAt: Date

    init(mealPlanId: String, recipeId: String, recipeName: String) {
        self.mealPlanId = mealPlanId
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.memberRatings = [:]
        self.overallNotes = ""
        self.wouldMakeAgain = true
        self.submittedAt = Date()
    }
}
