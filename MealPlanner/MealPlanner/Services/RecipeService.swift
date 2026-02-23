import Foundation

// MARK: - RecipeService
// Uses OpenAI GPT-4o to generate dinner recipe suggestions based on available
// pantry/fridge inventory and each family member's preferences.

class RecipeService {
    static let shared = RecipeService()

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
    }

    private init() {}

    // MARK: - Generate dinner suggestions

    /// Generates up to `count` dinner recipe suggestions given available food and family prefs.
    func generateDinnerSuggestions(
        availableFood: [FoodItem],
        familyMembers: [FamilyMember],
        count: Int = 3,
        excluding: [String] = []
    ) async throws -> [Recipe] {
        let foodList = availableFood.map { "\($0.quantity) \($0.unit) \($0.name)" }.joined(separator: ", ")
        let membersDescription = familyMembers.map { memberSummary($0) }.joined(separator: "\n")
        let exclusionLine = excluding.isEmpty ? "" :
            "- Do NOT suggest any of these recipes: \(excluding.joined(separator: ", "))\n"

        let prompt = """
        You are a professional family dinner planner. Generate \(count) dinner recipe suggestions.

        Available ingredients:
        \(foodList)

        Family members:
        \(membersDescription)

        Rules:
        - Generate \(count) DIFFERENT recipes — each must have a distinct name, cuisine, and cooking style.
        - Recipes must respect ALL dietary restrictions and allergies listed above.
        - Prefer ingredients already available, but a few extra items are acceptable.
        - Recipes should be practical for a weeknight dinner.
        \(exclusionLine)

        Respond ONLY with a valid JSON array of recipes. Each recipe must have:
        - name (string)
        - description (string, 1-2 sentences)
        - cuisine (string)
        - ingredients (array of {name, quantity (number), unit (string)})
        - instructions (array of strings, step by step)
        - prepTimeMinutes (number)
        - cookTimeMinutes (number)
        - servings (number)
        - tags (array of strings, e.g. ["Quick", "Kid-Friendly"])

        Example structure:
        [{"name":"Pasta Primavera","description":"...","cuisine":"Italian","ingredients":[{"name":"pasta","quantity":400,"unit":"g"}],"instructions":["Boil water..."],"prepTimeMinutes":10,"cookTimeMinutes":20,"servings":4,"tags":["Vegetarian"]}]
        """

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "max_tokens": 4000,
            "temperature": 0.9,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw RecipeServiceError.apiRequestFailed
        }

        return try parseRecipesResponse(data: data)
    }

    // MARK: - Private helpers

    private func memberSummary(_ member: FamilyMember) -> String {
        let prefs = member.preferences
        var lines: [String] = ["- \(member.name) (age \(member.age)):"]
        if !prefs.dietaryRestrictions.filter({ $0 != .none }).isEmpty {
            let restrictions = prefs.dietaryRestrictions.map { $0.rawValue }.joined(separator: ", ")
            lines.append("  Dietary restrictions: \(restrictions)")
        }
        if !prefs.allergies.isEmpty {
            lines.append("  Allergies: \(prefs.allergies.joined(separator: ", "))")
        }
        if !prefs.dislikedIngredients.isEmpty {
            lines.append("  Dislikes: \(prefs.dislikedIngredients.prefix(8).joined(separator: ", "))")
        }
        if !prefs.likedIngredients.isEmpty {
            lines.append("  Likes: \(prefs.likedIngredients.prefix(8).joined(separator: ", "))")
        }
        return lines.joined(separator: "\n")
    }

    private func parseRecipesResponse(data: Data) throws -> [Recipe] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw RecipeServiceError.unexpectedResponseFormat
        }

        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let arrayData = cleaned.data(using: .utf8),
              let rawRecipes = try JSONSerialization.jsonObject(with: arrayData) as? [[String: Any]] else {
            throw RecipeServiceError.jsonParsingFailed
        }

        return rawRecipes.compactMap { parseRecipe($0) }
    }

    private func parseRecipe(_ dict: [String: Any]) -> Recipe? {
        guard let name = dict["name"] as? String else { return nil }

        let rawIngredients = dict["ingredients"] as? [[String: Any]] ?? []
        let ingredients: [RecipeIngredient] = rawIngredients.compactMap { ing in
            guard let ingName = ing["name"] as? String else { return nil }
            let qty = ing["quantity"] as? Double ?? 1
            let unit = ing["unit"] as? String ?? "unit"
            return RecipeIngredient(name: ingName, quantity: qty, unit: unit)
        }

        return Recipe(
            id: nil,
            name: name,
            description: dict["description"] as? String ?? "",
            cuisine: dict["cuisine"] as? String ?? "International",
            ingredients: ingredients,
            instructions: dict["instructions"] as? [String] ?? [],
            prepTimeMinutes: dict["prepTimeMinutes"] as? Int ?? 15,
            cookTimeMinutes: dict["cookTimeMinutes"] as? Int ?? 30,
            servings: dict["servings"] as? Int ?? 4,
            imageURL: nil,
            tags: dict["tags"] as? [String] ?? [],
            averageRating: 0,
            ratingCount: 0,
            suitableForMembers: [],
            source: .aiGenerated
        )
    }

    enum RecipeServiceError: LocalizedError {
        case apiRequestFailed
        case unexpectedResponseFormat
        case jsonParsingFailed

        var errorDescription: String? {
            switch self {
            case .apiRequestFailed:         return "Recipe API request failed."
            case .unexpectedResponseFormat: return "Unexpected response from Recipe API."
            case .jsonParsingFailed:        return "Could not parse recipes from response."
            }
        }
    }
}
