import SwiftUI

struct FamilyProfilesView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @State private var showAddMember = false

    var body: some View {
        NavigationStack {
            Group {
                if familyVM.isLoading {
                    ProgressView("Loading family...")
                } else if familyVM.members.isEmpty {
                    emptyState
                } else {
                    memberList
                }
            }
            .navigationTitle("Family Profiles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddMember = true
                    } label: {
                        Label("Add Member", systemImage: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showAddMember) {
                AddFamilyMemberView()
            }
            .task { await familyVM.load() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("👨‍👩‍👧‍👦").font(.system(size: 64))
            Text("No family members yet")
                .font(.headline)
            Button("Add First Member") { showAddMember = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private var memberList: some View {
        List {
            ForEach(familyVM.members) { member in
                NavigationLink(destination: MemberProfileView(member: member)) {
                    MemberRow(member: member)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        Task {
                            if let id = member.id {
                                await familyVM.deleteMember(id: id)
                            }
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}

// MARK: - Member Row

struct MemberRow: View {
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 12) {
            Text(member.avatarEmoji).font(.largeTitle)
            VStack(alignment: .leading) {
                Text(member.name).font(.headline)
                Text("Age \(member.age)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !member.preferences.dietaryRestrictions.filter({ $0 != .none }).isEmpty {
                    let labels = member.preferences.dietaryRestrictions
                        .filter { $0 != .none }
                        .map { $0.rawValue }
                        .joined(separator: ", ")
                    Text(labels)
                        .font(.caption2)
                        .foregroundStyle(.purple)
                }
            }
            Spacer()
            VStack {
                if let lastRating = member.preferences.ratingHistory.last {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill").foregroundStyle(.yellow)
                        Text("\(lastRating.rating)").font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Member Profile View

struct MemberProfileView: View {
    let member: FamilyMember
    @EnvironmentObject var familyVM: FamilyViewModel
    @State private var editedMember: FamilyMember

    init(member: FamilyMember) {
        self.member = member
        _editedMember = State(initialValue: member)
    }

    var body: some View {
        Form {
            Section("Identity") {
                HStack {
                    Text("Avatar")
                    Spacer()
                    Text(editedMember.avatarEmoji).font(.largeTitle)
                }
                TextField("Name", text: $editedMember.name)
                Stepper("Age: \(editedMember.age)", value: $editedMember.age, in: 1...120)
            }

            Section("Dietary Restrictions") {
                ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                    MultipleSelectionRow(
                        label: restriction.rawValue,
                        isSelected: editedMember.preferences.dietaryRestrictions.contains(restriction)
                    ) {
                        if editedMember.preferences.dietaryRestrictions.contains(restriction) {
                            editedMember.preferences.dietaryRestrictions.removeAll { $0 == restriction }
                        } else {
                            editedMember.preferences.dietaryRestrictions.append(restriction)
                        }
                    }
                }
            }

            Section("Allergies") {
                if editedMember.preferences.allergies.isEmpty {
                    Text("None added").foregroundStyle(.secondary)
                } else {
                    ForEach(editedMember.preferences.allergies, id: \.self) { allergy in
                        Text(allergy)
                    }
                    .onDelete { indices in
                        editedMember.preferences.allergies.remove(atOffsets: indices)
                    }
                }
            }

            Section("Liked Ingredients") {
                tagCloud(tags: editedMember.preferences.likedIngredients, color: .green)
            }

            Section("Disliked Ingredients") {
                tagCloud(tags: editedMember.preferences.dislikedIngredients, color: .red)
            }

            if !editedMember.preferences.ratingHistory.isEmpty {
                Section("Recent Ratings") {
                    ForEach(editedMember.preferences.ratingHistory.suffix(5).reversed()) { rating in
                        HStack {
                            Text(rating.recipeName)
                            Spacer()
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating.rating ? "star.fill" : "star")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(editedMember.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task { await familyVM.updateMember(editedMember) }
                }
            }
        }
    }

    private func tagCloud(tags: [String], color: Color) -> some View {
        FlowLayout(tags: tags, color: color)
    }
}

// MARK: - Helpers

struct MultipleSelectionRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                }
            }
        }
        .foregroundStyle(.primary)
    }
}

struct FlowLayout: View {
    let tags: [String]
    let color: Color

    var body: some View {
        if tags.isEmpty {
            Text("None yet — updated after meals").foregroundStyle(.secondary).font(.caption)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(color.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

// MARK: - Add Family Member View

struct AddFamilyMemberView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var age = 30
    @State private var emoji = "👤"
    @State private var selectedRestrictions: [DietaryRestriction] = []
    @State private var allergiesText = ""

    let emojiOptions = ["👤", "👨", "👩", "👦", "👧", "🧑", "👴", "👵"]

    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(emojiOptions, id: \.self) { e in
                                Text(e)
                                    .font(.largeTitle)
                                    .padding(8)
                                    .background(emoji == e ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(Circle())
                                    .onTapGesture { emoji = e }
                            }
                        }
                    }
                    TextField("Name", text: $name)
                    Stepper("Age: \(age)", value: $age, in: 1...120)
                }

                Section("Dietary Restrictions") {
                    ForEach(DietaryRestriction.allCases.filter { $0 != .none }, id: \.self) { restriction in
                        MultipleSelectionRow(
                            label: restriction.rawValue,
                            isSelected: selectedRestrictions.contains(restriction)
                        ) {
                            if selectedRestrictions.contains(restriction) {
                                selectedRestrictions.removeAll { $0 == restriction }
                            } else {
                                selectedRestrictions.append(restriction)
                            }
                        }
                    }
                }

                Section("Allergies (comma separated)") {
                    TextField("e.g. peanuts, shellfish", text: $allergiesText)
                }
            }
            .navigationTitle("New Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            let allergies = allergiesText
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespaces) }
                                .filter { !$0.isEmpty }
                            let prefs = FoodPreferences(
                                dietaryRestrictions: selectedRestrictions,
                                allergies: allergies
                            )
                            let member = FamilyMember(name: name, age: age, avatarEmoji: emoji, preferences: prefs)
                            await familyVM.addMember(member)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
