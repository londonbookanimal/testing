import SwiftUI
import FirebaseCore

@main
struct MealPlannerApp: App {

    init() {
        FirebaseApp.configure()
    }

    // Shared ViewModels, injected into the environment so all views share the same state.
    @StateObject private var familyVM = FamilyViewModel()
    @StateObject private var inventoryVM = InventoryViewModel()
    @StateObject private var mealPlanVM = MealPlanViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(familyVM)
                .environmentObject(inventoryVM)
                .environmentObject(mealPlanVM)
        }
    }
}
