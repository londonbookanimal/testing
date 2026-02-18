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
                HStack(spacing: 16) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Choose Photo", systemImage: "photo")
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
                .padding(.horizontal)

                if inventoryVM.isScanning {
                    ProgressView("Identifying food items...")
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
        }
    }
}

// MARK: - Scanned Items Review View

struct ScannedItemsReviewView: View {
    let location: FoodLocation
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var items: [FoodItem] = []

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    Text("No items found. Try taking a clearer photo.")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    List {
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
}
