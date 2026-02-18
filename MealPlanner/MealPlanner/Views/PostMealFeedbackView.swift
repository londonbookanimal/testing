import SwiftUI

struct PostMealFeedbackView: View {
    let mealPlan: MealPlan
    let recipe: Recipe

    @EnvironmentObject var familyVM: FamilyViewModel
    @StateObject private var feedbackVM = FeedbackViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var memberRatings: [String: Int] = [:]      // memberId → rating
    @State private var memberComments: [String: String] = [:]  // memberId → comment
    @State private var overallNotes = ""
    @State private var wouldMakeAgain = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.name).font(.headline)
                        Text(recipe.cuisine).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Per-member ratings
                ForEach(familyVM.members) { member in
                    Section("\(member.avatarEmoji) \(member.name)") {
                        StarRatingPicker(
                            rating: Binding(
                                get: { memberRatings[member.id ?? ""] ?? 3 },
                                set: { memberRatings[member.id ?? ""] = $0 }
                            )
                        )
                        TextField("Comment (optional)", text: Binding(
                            get: { memberComments[member.id ?? ""] ?? "" },
                            set: { memberComments[member.id ?? ""] = $0 }
                        ))
                    }
                }

                Section("Overall") {
                    TextField("Notes about the meal", text: $overallNotes, axis: .vertical)
                        .lineLimit(3...6)
                    Toggle("Would make again", isOn: $wouldMakeAgain)
                }
            }
            .navigationTitle("Rate Tonight's Dinner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task { await submitFeedback() }
                    }
                    .disabled(feedbackVM.isSubmitting)
                }
            }
            .onChange(of: feedbackVM.submittedSuccessfully) { _, success in
                if success { dismiss() }
            }
        }
        .onAppear {
            // Pre-fill with 3 stars for each member
            for member in familyVM.members {
                if let id = member.id {
                    memberRatings[id] = 3
                }
            }
        }
    }

    private func submitFeedback() async {
        guard let planId = mealPlan.id, let recipeId = recipe.id else { return }
        var feedback = PostMealFeedback(mealPlanId: planId, recipeId: recipeId, recipeName: recipe.name)
        feedback.overallNotes = overallNotes
        feedback.wouldMakeAgain = wouldMakeAgain

        for member in familyVM.members {
            guard let memberId = member.id else { continue }
            let rating = memberRatings[memberId] ?? 3
            let comment = memberComments[memberId] ?? ""
            let mealRating = MealRating(
                recipeId: recipeId,
                recipeName: recipe.name,
                rating: rating,
                comment: comment
            )
            feedback.memberRatings[memberId] = mealRating
        }

        await feedbackVM.submitFeedback(feedback: feedback, recipe: recipe, familyVM: familyVM)
    }
}

// MARK: - Star Rating Picker

struct StarRatingPicker: View {
    @Binding var rating: Int

    var body: some View {
        HStack {
            Text("Rating")
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundStyle(star <= rating ? .yellow : .secondary)
                        .font(.title3)
                        .onTapGesture { rating = star }
                }
            }
        }
    }
}
