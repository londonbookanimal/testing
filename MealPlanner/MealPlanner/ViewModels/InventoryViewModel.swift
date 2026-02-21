import Foundation
import Combine
import UIKit

@MainActor
class InventoryViewModel: ObservableObject {
    @Published var fridgeItems: [FoodItem] = []
    @Published var pantryItems: [FoodItem] = []
    @Published var freezerItems: [FoodItem] = []
    @Published var isLoading = false
    @Published var isScanning = false
    @Published var scannedItems: [FoodItem] = []
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared
    private let vision = VisionService.shared

    var allItems: [FoodItem] { fridgeItems + pantryItems + freezerItems }

    var expiringItems: [FoodItem] {
        allItems.filter { $0.isExpiringSoon }.sorted { ($0.expiryDate ?? .distantFuture) < ($1.expiryDate ?? .distantFuture) }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        async let fridge = firebase.fetchFoodItems(location: .fridge)
        async let pantry = firebase.fetchFoodItems(location: .pantry)
        async let freezer = firebase.fetchFoodItems(location: .freezer)
        do {
            (fridgeItems, pantryItems, freezerItems) = try await (fridge, pantry, freezer)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func items(for location: FoodLocation) -> [FoodItem] {
        switch location {
        case .fridge:  return fridgeItems
        case .pantry:  return pantryItems
        case .freezer: return freezerItems
        }
    }

    /// Sends a photo to Vision API and populates scannedItems for user review.
    func scanImage(_ image: UIImage, location: FoodLocation) async {
        isScanning = true
        defer { isScanning = false }
        do {
            scannedItems = try await vision.identifyFoodItems(in: image, location: location)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Sends a receipt photo to Vision API and populates scannedItems for user review.
    func scanReceipt(_ image: UIImage, defaultLocation: FoodLocation) async {
        isScanning = true
        defer { isScanning = false }
        do {
            scannedItems = try await vision.scanReceipt(image: image, defaultLocation: defaultLocation)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Saves the user-confirmed scanned items to Firebase and updates local state.
    func confirmScannedItems(location: FoodLocation) async {
        do {
            try await firebase.bulkSaveFoodItems(scannedItems)
            await load()
            scannedItems = []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addItem(_ item: FoodItem) async {
        do {
            let saved = try await firebase.saveFoodItem(item)
            append(saved)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteItem(_ item: FoodItem) async {
        guard let id = item.id else { return }
        do {
            try await firebase.deleteFoodItem(id: id)
            remove(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Local state helpers

    private func append(_ item: FoodItem) {
        switch item.location {
        case .fridge:  fridgeItems.append(item)
        case .pantry:  pantryItems.append(item)
        case .freezer: freezerItems.append(item)
        }
    }

    private func remove(id: String) {
        fridgeItems.removeAll  { $0.id == id }
        pantryItems.removeAll  { $0.id == id }
        freezerItems.removeAll { $0.id == id }
    }
}
