import SwiftUI
import PhotosUI

struct InventoryView: View {
    let location: FoodLocation
    @EnvironmentObject var inventoryVM: InventoryViewModel

    @State private var showCamera = false
    @State private var showAddItem = false
    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory?

    private var items: [FoodItem] { inventoryVM.items(for: location) }

    private var filteredItems: [FoodItem] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    private var grouped: [FoodCategory: [FoodItem]] {
        Dictionary(grouping: filteredItems) { $0.category }
    }

    var body: some View {
        NavigationStack {
            Group {
                if inventoryVM.isLoading {
                    ProgressView("Loading \(location.rawValue)...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if items.isEmpty {
                    emptyState
                } else {
                    itemList
                }
            }
            .navigationTitle(location.rawValue)
            .searchable(text: $searchText, prompt: "Search items")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Scan", systemImage: "camera.fill")
                    }
                    Button {
                        showAddItem = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView(location: location)
            }
            .sheet(isPresented: $showAddItem) {
                AddFoodItemView(location: location)
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 20) {
            Text(location == .fridge ? "🧊" : location == .pantry ? "🫙" : "❄️")
                .font(.system(size: 64))
            Text("Your \(location.rawValue.lowercased()) is empty")
                .font(.headline)
            Text("Tap the camera icon to scan items, or use + to add manually.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var itemList: some View {
        List {
            ForEach(FoodCategory.allCases, id: \.self) { category in
                if let categoryItems = grouped[category], !categoryItems.isEmpty {
                    Section {
                        ForEach(categoryItems) { item in
                            FoodItemRow(item: item)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        Task { await inventoryVM.deleteItem(item) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        Label("\(category.emoji) \(category.rawValue)", systemImage: "")
                    }
                }
            }
        }
    }
}

// MARK: - Food Item Row

struct FoodItemRow: View {
    let item: FoodItem

    var body: some View {
        HStack {
            Text(item.category.emoji).font(.title3)
            VStack(alignment: .leading) {
                Text(item.name).font(.body)
                Text("\(item.quantity, specifier: "%.0f") \(item.unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if item.isExpired {
                Text("Expired").font(.caption).foregroundStyle(.red)
            } else if item.isExpiringSoon {
                Text("Soon").font(.caption).foregroundStyle(.orange)
            }
        }
    }
}

// MARK: - Add Food Item View

struct AddFoodItemView: View {
    let location: FoodLocation
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: FoodCategory = .other
    @State private var quantity = 1.0
    @State private var unit = "unit"
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .week, value: 1, to: Date()) ?? Date()
    @State private var hasExpiry = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Info") {
                    TextField("Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(FoodCategory.allCases, id: \.self) { cat in
                            Text("\(cat.emoji) \(cat.rawValue)").tag(cat)
                        }
                    }
                }
                Section("Quantity") {
                    HStack {
                        Stepper("\(Int(quantity))", value: $quantity, in: 0.5...100, step: 0.5)
                        TextField("Unit", text: $unit)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section("Expiry") {
                    Toggle("Has expiry date", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("Expires", selection: $expiryDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            let item = FoodItem(
                                name: name,
                                category: category,
                                quantity: quantity,
                                unit: unit,
                                location: location,
                                expiryDate: hasExpiry ? expiryDate : nil
                            )
                            await inventoryVM.addItem(item)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
