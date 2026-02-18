import Foundation
import Combine

@MainActor
class FamilyViewModel: ObservableObject {
    @Published var members: [FamilyMember] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            members = try await firebase.fetchFamilyMembers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addMember(_ member: FamilyMember) async {
        do {
            let saved = try await firebase.saveFamilyMember(member)
            members.append(saved)
            members.sort { $0.name < $1.name }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateMember(_ member: FamilyMember) async {
        do {
            let saved = try await firebase.saveFamilyMember(member)
            if let index = members.firstIndex(where: { $0.id == saved.id }) {
                members[index] = saved
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMember(id: String) async {
        do {
            try await firebase.deleteFamilyMember(id: id)
            members.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Adds a rating to a member's history and updates liked/disliked ingredient lists
    /// based on the rating score (≥4 = liked, ≤2 = disliked).
    func recordRating(memberId: String, rating: MealRating, recipe: Recipe) async {
        guard let index = members.firstIndex(where: { $0.id == memberId }) else { return }
        var member = members[index]

        member.preferences.ratingHistory.append(rating)

        let ingredientNames = recipe.ingredients.map { $0.name.lowercased() }
        if rating.rating >= 4 {
            for ingredient in ingredientNames
                where !member.preferences.likedIngredients.contains(ingredient) {
                member.preferences.likedIngredients.append(ingredient)
                member.preferences.dislikedIngredients.removeAll { $0 == ingredient }
            }
        } else if rating.rating <= 2 {
            for ingredient in ingredientNames
                where !member.preferences.dislikedIngredients.contains(ingredient) {
                member.preferences.dislikedIngredients.append(ingredient)
                member.preferences.likedIngredients.removeAll { $0 == ingredient }
            }
        }

        member.updatedAt = Date()
        await updateMember(member)
    }
}
