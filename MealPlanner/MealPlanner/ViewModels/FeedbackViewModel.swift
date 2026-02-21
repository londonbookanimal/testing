import Foundation
import Combine

@MainActor
class FeedbackViewModel: ObservableObject {
    @Published var isSubmitting = false
    @Published var submittedSuccessfully = false
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared

    /// Saves post-meal feedback and updates each family member's preference profile.
    func submitFeedback(
        feedback: PostMealFeedback,
        recipe: Recipe,
        familyVM: FamilyViewModel
    ) async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await firebase.saveFeedback(feedback)

            // Update recipe average rating
            let allRatings = feedback.memberRatings.values.map { Double($0.rating) }
            if !allRatings.isEmpty, let recipeId = recipe.id {
                let newAvg = allRatings.reduce(0, +) / Double(allRatings.count)
                let newCount = (recipe.ratingCount) + 1
                try await firebase.updateRecipeRating(recipeId: recipeId, newRating: newAvg, ratingCount: newCount)
            }

            // Update each member's preference profile
            for (memberId, rating) in feedback.memberRatings {
                await familyVM.recordRating(memberId: memberId, rating: rating, recipe: recipe)
            }

            submittedSuccessfully = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
