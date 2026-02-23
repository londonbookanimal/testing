import SwiftUI

struct HomeView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @EnvironmentObject var mealPlanVM: MealPlanViewModel
    @EnvironmentObject var familyVM: FamilyViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Tonight's dinner card
                    TonightsDinnerCard()

                    // Quick action tiles
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        NavigationLink(destination: InventoryView(location: nil)) {
                            QuickActionTile(title: "Food", emoji: "🛒", color: .teal)
                        }
                        NavigationLink(destination: FamilyProfilesView()) {
                            QuickActionTile(title: "Family", emoji: "👨‍👩‍👧‍👦", color: .purple)
                        }
                        NavigationLink(destination: WeeklyMealPlanView()) {
                            QuickActionTile(title: "Meal Plan", emoji: "📅", color: .green)
                        }
                    }

                    // Expiring soon banner
                    if !inventoryVM.expiringItems.isEmpty {
                        ExpiringItemsBanner(items: inventoryVM.expiringItems)
                    }
                }
                .padding()
            }
            .navigationTitle("What's For Dinner")
            .task {
                await inventoryVM.load()
                await mealPlanVM.loadWeek()
                await familyVM.load()
            }
        }
    }
}

// MARK: - Tonight's Dinner Card

struct TonightsDinnerCard: View {
    @EnvironmentObject var mealPlanVM: MealPlanViewModel
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @EnvironmentObject var familyVM: FamilyViewModel

    @State private var showFeedback = false

    private var tonightsPlan: MealPlan? { mealPlanVM.plan(for: Date()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tonight's Dinner")
                .font(.headline)
                .foregroundStyle(.secondary)

            if let plan = tonightsPlan, let recipe = plan.dinnerRecipe {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.name)
                        .font(.title2.bold())
                    Text(recipe.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Label(recipe.formattedTotalTime, systemImage: "clock")
                        Spacer()
                        Label(recipe.cuisine, systemImage: "fork.knife")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if plan.status == .cooked && !plan.feedbackSubmitted {
                        Button("Rate This Meal") {
                            showFeedback = true
                        }
                        .buttonStyle(.borderedProminent)
                        .sheet(isPresented: $showFeedback) {
                            PostMealFeedbackView(mealPlan: plan, recipe: recipe)
                        }
                    } else if plan.status != .cooked {
                        Button("Mark as Cooked") {
                            Task {
                                if let id = plan.id {
                                    await mealPlanVM.markCooked(planId: id)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("No dinner planned yet")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                    Button("Get Suggestions") {
                        Task {
                            await mealPlanVM.generateSuggestions(
                                inventory: inventoryVM.allItems,
                                family: familyVM.members
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    if mealPlanVM.isGenerating {
                        ProgressView("Finding recipes...")
                            .frame(maxWidth: .infinity)
                    }
                    if !mealPlanVM.suggestedRecipes.isEmpty {
                        Divider()
                        Text("Tonight's Options")
                            .font(.subheadline.bold())
                        ForEach(mealPlanVM.suggestedRecipes) { recipe in
                            RecipeSuggestionCard(recipe: recipe) {
                                Task { await mealPlanVM.assignRecipe(recipe, toDate: Date()) }
                            } onDismiss: {
                                mealPlanVM.dismissSuggestion(recipe)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Quick Action Tile

struct QuickActionTile: View {
    let title: String
    let emoji: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji).font(.largeTitle)
            Text(title).font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Expiring Items Banner

struct ExpiringItemsBanner: View {
    let items: [FoodItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Use Soon", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            ForEach(items.prefix(3)) { item in
                HStack {
                    Text(item.name)
                    Spacer()
                    if let expiry = item.expiryDate {
                        Text(expiry, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
