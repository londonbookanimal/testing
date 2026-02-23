import SwiftUI

struct WeeklyMealPlanView: View {
    @EnvironmentObject var mealPlanVM: MealPlanViewModel
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @EnvironmentObject var familyVM: FamilyViewModel

    @State private var selectedDate: Date = Date()
    @State private var showSuggestions = false

    private var weekDays: [Date] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfToday) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Day selector strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(weekDays, id: \.self) { day in
                            DayChip(
                                date: day,
                                isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate),
                                hasRecipe: mealPlanVM.plan(for: day)?.dinnerRecipe != nil
                            ) {
                                selectedDate = day
                            }
                        }
                    }
                    .padding()
                }
                .background(.bar)

                Divider()

                // Content for selected day
                ScrollView {
                    VStack(spacing: 20) {
                        if let plan = mealPlanVM.plan(for: selectedDate), let recipe = plan.dinnerRecipe {
                            PlannedRecipeCard(plan: plan, recipe: recipe)
                        } else {
                            noRecipePlaceholder
                        }

                        if !mealPlanVM.suggestedRecipes.isEmpty {
                            suggestionsList
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Meal Plan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await mealPlanVM.generateSuggestions(
                                inventory: inventoryVM.allItems,
                                family: familyVM.members
                            )
                        }
                    } label: {
                        Label("Get Ideas", systemImage: "sparkles")
                    }
                    .disabled(mealPlanVM.isGenerating)
                }
            }
            .task { await mealPlanVM.loadWeek() }
        }
    }

    // MARK: - Subviews

    private var noRecipePlaceholder: some View {
        VStack(spacing: 12) {
            Text("📅").font(.system(size: 48))
            Text("No dinner planned")
                .font(.headline)
            Text("Tap 'Get Ideas' to generate recipe suggestions based on what's in your food list.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if mealPlanVM.isGenerating {
                ProgressView("Thinking of recipes...")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggestions")
                .font(.headline)

            ForEach(mealPlanVM.suggestedRecipes) { recipe in
                RecipeSuggestionCard(recipe: recipe) {
                    Task { await mealPlanVM.assignRecipe(recipe, toDate: selectedDate) }
                } onDismiss: {
                    mealPlanVM.dismissSuggestion(recipe)
                }
            }
        }
    }
}

// MARK: - Day Chip

struct DayChip: View {
    let date: Date
    let isSelected: Bool
    let hasRecipe: Bool
    let action: () -> Void

    private var dayLetter: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayLetter).font(.caption2).foregroundStyle(.secondary)
                Text(dayNumber).font(.headline)
                Circle()
                    .fill(hasRecipe ? Color.green : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 44)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Planned Recipe Card

struct PlannedRecipeCard: View {
    let plan: MealPlan
    let recipe: Recipe
    @EnvironmentObject var mealPlanVM: MealPlanViewModel
    @State private var showFeedback = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(recipe.name).font(.title2.bold())
                Spacer()
                Button(role: .destructive) {
                    Task { await mealPlanVM.removeRecipeFromPlan(plan) }
                } label: {
                    Image(systemName: "trash")
                }
            }
            Text(recipe.description).foregroundStyle(.secondary)

            HStack {
                Label(recipe.formattedTotalTime, systemImage: "clock")
                Spacer()
                Label(recipe.cuisine, systemImage: "fork.knife")
                Spacer()
                Label("\(recipe.servings) servings", systemImage: "person.2")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(recipe.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }

            Divider()

            // Ingredients
            Text("Ingredients").font(.headline)
            ForEach(recipe.ingredients) { ing in
                HStack {
                    Text("•")
                    Text("\(ing.quantity, specifier: "%.0f") \(ing.unit) \(ing.name)")
                    Spacer()
                }
                .font(.subheadline)
            }

            Divider()

            // Instructions
            Text("Steps").font(.headline)
            ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.subheadline.bold())
                        .frame(width: 24, alignment: .leading)
                    Text(step).font(.subheadline)
                }
            }

            Divider()

            HStack {
                if plan.status != .cooked {
                    Button("Mark as Cooked") {
                        Task {
                            if let id = plan.id {
                                await mealPlanVM.markCooked(planId: id)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Label("Cooked!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Spacer()

                if plan.status == .cooked && !plan.feedbackSubmitted {
                    Button("Rate Meal") { showFeedback = true }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showFeedback) {
            PostMealFeedbackView(mealPlan: plan, recipe: recipe)
        }
    }
}

// MARK: - Recipe Suggestion Card

struct RecipeSuggestionCard: View {
    let recipe: Recipe
    let onAssign: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recipe.name).font(.headline)
                Spacer()
                Text(recipe.cuisine)
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            Text(recipe.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Label(recipe.formattedTotalTime, systemImage: "clock")
                Spacer()
                Button("Plan This", action: onAssign)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .font(.caption)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
