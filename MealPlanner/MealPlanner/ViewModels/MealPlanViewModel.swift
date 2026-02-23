import Foundation
import Combine

@MainActor
class MealPlanViewModel: ObservableObject {
    @Published var mealPlans: [MealPlan] = []
    @Published var suggestedRecipes: [Recipe] = []
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared
    private let recipeService = RecipeService.shared
    private var seenRecipeNames: Set<String> = []

    // MARK: - Load

    func loadWeek(startingFrom date: Date = Date()) async {
        isLoading = true
        defer { isLoading = false }
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: date) ?? date
        do {
            mealPlans = try await firebase.fetchMealPlans(from: date, to: endDate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Generate suggestions

    func generateSuggestions(inventory: [FoodItem], family: [FamilyMember]) async {
        isGenerating = true
        defer { isGenerating = false }
        do {
            suggestedRecipes = try await recipeService.generateDinnerSuggestions(
                availableFood: inventory,
                familyMembers: family,
                count: 3,
                excludeRecipeNames: Array(seenRecipeNames)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Plan management

    func assignRecipe(_ recipe: Recipe, toDate date: Date) async {
        seenRecipeNames.insert(recipe.name)
        var plan = MealPlan(date: date, dinnerRecipeId: recipe.id)
        plan.dinnerRecipe = recipe
        do {
            var saved = try await firebase.saveMealPlan(plan)
            saved.dinnerRecipe = recipe
            if let index = mealPlans.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                mealPlans[index] = saved
            } else {
                mealPlans.append(saved)
                mealPlans.sort { $0.date < $1.date }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markCooked(planId: String) async {
        do {
            try await firebase.markMealPlanCooked(id: planId)
            if let index = mealPlans.firstIndex(where: { $0.id == planId }) {
                mealPlans[index].status = .cooked
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeRecipeFromPlan(_ plan: MealPlan) async {
        guard let id = plan.id else { return }
        do {
            try await firebase.deleteMealPlan(id: id)
            mealPlans.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dismissSuggestion(_ recipe: Recipe) {
        seenRecipeNames.insert(recipe.name)
        suggestedRecipes.removeAll { $0.id == recipe.id }
    }

    func plan(for date: Date) -> MealPlan? {
        mealPlans.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}
