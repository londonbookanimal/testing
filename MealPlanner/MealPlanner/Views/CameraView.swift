import SwiftUI
import PhotosUI

struct CameraView: View {
    let location: FoodLocation
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var showReview = false
    @State private var showCameraCapture = false

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
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("Take or choose a photo of your \(location.rawValue.lowercased())")
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

                        if capturedImage != nil {
                            Button {
                                Task {
                                    if let image = capturedImage {
                                        await inventoryVM.scanImage(image, location: location)
                                        showReview = true
                                    }
                                }
                            } label: {
                                Label("Scan Items", systemImage: "sparkles")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(inventoryVM.isScanning)
                        }
                    }

                    if capturedImage != nil {
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
                    ProgressView("Scanning...")
                }
            }
            .navigationTitle("Scan \(location.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showReview) {
                ScannedItemsReviewView(location: location)
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

// MARK: - Scanned Items Review View

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
                            await inventoryVM.confirmScannedItems(location: location)
                            dismiss()
                        }
                    }
                    .disabled(items.isEmpty)
                }
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
