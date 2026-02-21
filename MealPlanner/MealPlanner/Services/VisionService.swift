import Foundation
import UIKit

// MARK: - VisionService
// Uses OpenAI GPT-4o Vision to identify food items from photos of the fridge or pantry.
// Requires OPENAI_API_KEY in Info.plist or passed at init.

class VisionService {
    static let shared = VisionService()

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
    }

    private init() {}

    // MARK: - Analyze fridge/pantry image

    /// Sends an image to GPT-4o Vision and returns a list of identified food items.
    func identifyFoodItems(in image: UIImage, location: FoodLocation) async throws -> [FoodItem] {
        guard let base64Image = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            throw VisionError.imageEncodingFailed
        }

        let prompt = """
        You are a food inventory assistant. Analyze this photo of a \(location.rawValue.lowercased()).
        List every visible food item you can identify.

        Respond ONLY with a valid JSON array. Each element must have these fields:
        - name (string): common name of the food
        - category (string): one of [Produce, Dairy, Meat & Seafood, Grains & Pasta, Canned Goods, Condiments & Sauces, Spices & Seasonings, Frozen, Snacks, Beverages, Other]
        - quantity (number): estimated quantity (use 1 if unsure)
        - unit (string): appropriate unit (e.g. "bunch", "bottle", "bag", "oz", "lb", "unit")

        Example: [{"name":"Whole Milk","category":"Dairy","quantity":1,"unit":"jug"},{"name":"Broccoli","category":"Produce","quantity":1,"unit":"head"}]
        """

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "max_tokens": 1000,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw VisionError.apiRequestFailed
        }

        return try parseVisionResponse(data: data, location: location)
    }

    // MARK: - Private parsing

    private func parseVisionResponse(data: Data, location: FoodLocation) throws -> [FoodItem] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw VisionError.unexpectedResponseFormat
        }

        // Strip markdown code fences if present
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let arrayData = cleaned.data(using: .utf8),
              let rawItems = try JSONSerialization.jsonObject(with: arrayData) as? [[String: Any]] else {
            throw VisionError.jsonParsingFailed
        }

        return rawItems.compactMap { dict -> FoodItem? in
            guard let name = dict["name"] as? String else { return nil }
            let categoryRaw = dict["category"] as? String ?? "Other"
            let category = FoodCategory.allCases.first { $0.rawValue == categoryRaw } ?? .other
            let quantity = dict["quantity"] as? Double ?? 1
            let unit = dict["unit"] as? String ?? "unit"
            return FoodItem(name: name, category: category, quantity: quantity, unit: unit, location: location)
        }
    }

    // MARK: - Analyse receipt image

    /// Sends a receipt photo to GPT-4o Vision and returns a list of purchased food items,
    /// each assigned to the most appropriate storage location.
    func scanReceipt(image: UIImage, defaultLocation: FoodLocation) async throws -> [FoodItem] {
        guard let base64Image = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            throw VisionError.imageEncodingFailed
        }

        let prompt = """
        You are a grocery receipt scanner. Extract all food and grocery items from this receipt image.

        Respond ONLY with a valid JSON array. Each element must have these fields:
        - name (string): the product name (clean it up, remove SKUs or price codes)
        - category (string): one of [Produce, Dairy, Meat & Seafood, Grains & Pasta, Canned Goods, Condiments & Sauces, Spices & Seasonings, Frozen, Snacks, Beverages, Other]
        - quantity (number): quantity purchased (use 1 if not shown)
        - unit (string): appropriate unit (e.g. "unit", "bag", "bottle", "pack")
        - location (string): where this item is typically stored — one of [Fridge, Pantry, Freezer]
          • Fridge: fresh produce, dairy, meat, fish, opened sauces, fresh juice, eggs
          • Pantry: tins, canned goods, dry pasta, rice, cereals, bread, crisps, biscuits, cooking oils, condiments (unopened), long-life drinks
          • Freezer: frozen meals, frozen veg, frozen meat, ice cream

        Only include food and drink items. Ignore non-food items like cleaning products, toiletries, or household goods.

        Example: [{"name":"Whole Milk","category":"Dairy","quantity":1,"unit":"jug","location":"Fridge"},{"name":"Baked Beans","category":"Canned Goods","quantity":2,"unit":"tin","location":"Pantry"},{"name":"Frozen Peas","category":"Frozen","quantity":1,"unit":"bag","location":"Freezer"}]
        """

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "max_tokens": 1500,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw VisionError.apiRequestFailed
        }

        return try parseReceiptResponse(data: data, defaultLocation: defaultLocation)
    }

    private func parseReceiptResponse(data: Data, defaultLocation: FoodLocation) throws -> [FoodItem] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw VisionError.unexpectedResponseFormat
        }

        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let arrayData = cleaned.data(using: .utf8),
              let rawItems = try JSONSerialization.jsonObject(with: arrayData) as? [[String: Any]] else {
            throw VisionError.jsonParsingFailed
        }

        return rawItems.compactMap { dict -> FoodItem? in
            guard let name = dict["name"] as? String else { return nil }
            let categoryRaw = dict["category"] as? String ?? "Other"
            let category = FoodCategory.allCases.first { $0.rawValue == categoryRaw } ?? .other
            let quantity = dict["quantity"] as? Double ?? 1
            let unit = dict["unit"] as? String ?? "unit"
            let locationRaw = dict["location"] as? String ?? defaultLocation.rawValue
            let location = FoodLocation.allCases.first { $0.rawValue == locationRaw } ?? defaultLocation
            return FoodItem(name: name, category: category, quantity: quantity, unit: unit, location: location)
        }
    }

    // MARK: - Errors

    enum VisionError: LocalizedError {
        case imageEncodingFailed
        case apiRequestFailed
        case unexpectedResponseFormat
        case jsonParsingFailed

        var errorDescription: String? {
            switch self {
            case .imageEncodingFailed:     return "Could not encode image."
            case .apiRequestFailed:        return "Vision API request failed."
            case .unexpectedResponseFormat: return "Unexpected response from Vision API."
            case .jsonParsingFailed:       return "Could not parse food items from response."
            }
        }
    }
}
