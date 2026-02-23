import SwiftUI
import PhotosUI

enum ScanMode {
    case add   // scan items to add to food list
    case use   // scan items to remove from food list
}

struct CameraView: View {
    let location: FoodLocation
    var mode: ScanMode = .add
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var showReview = false
    @State private var showCameraCapture = false

    private var navTitle: String {
        mode == .use ? "Use Food" : "Scan Food"
    }

    private var placeholderText: String {
        mode == .use
            ? "Take a photo of what you're about to use"
            : "Take or choose a photo of your food"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 280)
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: mode == .use ? "minus.circle.fill" : "camera.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(mode == .use ? .orange : .secondary)
                                Text(placeholderText)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                }

                // Buttons
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Button {
                            showCameraCapture = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    capturedImage = image
                                }
                            }
                        }
                    }

                    if capturedImage != nil {
                        Button {
                            Task {
                                if let image = capturedImage {
                                    await inventoryVM.scanImage(image, location: location)
                                    showReview = true
                                }
                            }
                        } label: {
                            Label(
                                mode == .use ? "Identify Items to Remove" : "Scan Items",
                                systemImage: mode == .use ? "minus.circle" : "sparkles"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(mode == .use ? .orange : .accentColor)
                        .disabled(inventoryVM.isScanning)
                    }

                    if capturedImage != nil && mode == .add {
                        Button {
                            Task {
                                if let image = capturedImage {
                                    await inventoryVM.scanReceipt(image, defaultLocation: location)
                                    showReview = true
                                }
                            }
                        } label: {
                            Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(inventoryVM.isScanning)
                    }
                }
                .padding(.horizontal)

                if inventoryVM.isScanning {
                    ProgressView(mode == .use ? "Identifying items..." : "Scanning...")
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Scan Failed", isPresented: Binding(
                get: { inventoryVM.errorMessage != nil && !showReview },
                set: { if !$0 { inventoryVM.errorMessage = nil } }
            )) {
                Button("OK") { inventoryVM.errorMessage = nil }
            } message: {
                Text(inventoryVM.errorMessage ?? "")
            }
            .sheet(isPresented: $showReview) {
                if mode == .use {
                    UseFoodReviewView()
                } else {
                    ScannedItemsReviewView(location: location)
                }
            }
            .sheet(isPresented: $showCameraCapture) {
                CameraCaptureView(image: $capturedImage)
            }
        }
    }
}

// MARK: - Camera Capture (wraps UIImagePickerController)

struct CameraCaptureView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView
        init(_ parent: CameraCaptureView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Scanned Items Review View (add mode)

struct ScannedItemsReviewView: View {
    let location: FoodLocation
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var items: [FoodItem] = []

    private var hasMultipleLocations: Bool {
        Set(items.map(\.location)).count > 1
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    Text("No items found. Try taking a clearer photo.")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    List {
                        if hasMultipleLocations {
                            Section {
                                Label("Items have been sorted into Fridge, Pantry, and Freezer automatically. Tap a location badge to change it.",
                                      systemImage: "info.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Section("Found \(items.count) item(s) — remove any that are wrong") {
                            ForEach(items.indices, id: \.self) { index in
                                HStack {
                                    Text(items[index].category.emoji)
                                    VStack(alignment: .leading) {
                                        Text(items[index].name)
                                        Text("\(items[index].quantity, specifier: "%.0f") \(items[index].unit)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Menu {
                                        ForEach(FoodLocation.allCases, id: \.self) { loc in
                                            Button {
                                                items[index].location = loc
                                            } label: {
                                                Label(loc.rawValue, systemImage: locationIcon(loc))
                                            }
                                        }
                                    } label: {
                                        Text(items[index].location.rawValue)
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(locationColor(items[index].location).opacity(0.15))
                                            .foregroundStyle(locationColor(items[index].location))
                                            .clipShape(Capsule())
                                    }
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        items.remove(at: index)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Review Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add All") {
                        inventoryVM.scannedItems = items
                        Task {
                            let saved = await inventoryVM.confirmScannedItems(location: location)
                            if saved { dismiss() }
                        }
                    }
                    .disabled(items.isEmpty)
                }
            }
            .alert("Could Not Save", isPresented: Binding(
                get: { inventoryVM.errorMessage != nil },
                set: { if !$0 { inventoryVM.errorMessage = nil } }
            )) {
                Button("OK") { inventoryVM.errorMessage = nil }
            } message: {
                Text(inventoryVM.errorMessage ?? "")
            }
            .onAppear {
                items = inventoryVM.scannedItems
            }
        }
    }

    private func locationIcon(_ location: FoodLocation) -> String {
        switch location {
        case .fridge:  return "thermometer.snowflake"
        case .pantry:  return "cabinet"
        case .freezer: return "snowflake"
        }
    }

    private func locationColor(_ location: FoodLocation) -> Color {
        switch location {
        case .fridge:  return .blue
        case .pantry:  return .orange
        case .freezer: return .cyan
        }
    }
}

// MARK: - Use Food Review View (remove mode)

struct UseFoodReviewView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var items: [FoodItem] = []

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No matching items found")
                            .font(.headline)
                        Text("None of the scanned items matched anything in your food list.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        Section("These items will be removed from your food list") {
                            ForEach(items.indices, id: \.self) { index in
                                HStack {
                                    Text(items[index].category.emoji)
                                    Text(items[index].name)
                                    Spacer()
                                    Text(items[index].location.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        items.remove(at: index)
                                    } label: {
                                        Label("Keep", systemImage: "arrow.uturn.left")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Using These?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if !items.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Remove from Food") {
                            Task {
                                await inventoryVM.removeMatchedItems(items)
                                dismiss()
                            }
                        }
                        .tint(.orange)
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { inventoryVM.errorMessage != nil },
                set: { if !$0 { inventoryVM.errorMessage = nil } }
            )) {
                Button("OK") { inventoryVM.errorMessage = nil }
            } message: {
                Text(inventoryVM.errorMessage ?? "")
            }
            .onAppear {
                // Match scanned items against inventory by name
                items = inventoryVM.matchItemsInInventory(inventoryVM.scannedItems)
            }
        }
    }
}
