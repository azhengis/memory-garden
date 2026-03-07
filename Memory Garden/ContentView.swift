import SwiftUI

struct ContentView: View {
    @ObservedObject var store: MemoryStore

    @State private var previewTransform: [Float]?
    @State private var previewPlantType: PlantType?
    @State private var pendingMemoryForPlacement: Memory?
    
    @State private var showAdd = false
    @State private var pendingTransform: [Float]?

    
    @State private var selectedMemory: Memory?
    @State private var showMemory = false

    var body: some View {
        ZStack(alignment: .top) {
            ARContainerView(
                planted: store.planted, memories: store.memories,
                previewTransform: previewTransform,
                previewPlantType: previewPlantType,
                onSelectMemory: { memoryID in
                    if let mem = store.memories.first(where: { $0.id == memoryID }) {
                        selectedMemory = mem
                        showMemory = true
                    }
                },
                onRequestNewMemory: { transform, _ in
                    pendingTransform = transform
                    showAdd = true
                },

                onConfirmPlacement: {
                    confirmPlacement()
                },

                onCancelPlacement: {
                    previewTransform = nil
                    previewPlantType = nil
                },
                onDeleteMemoryPlant: { plantedID in
                    store.deletePlantedByMemoryID(plantedID)
                },
                onMoveMemoryPlant: { plantedID, newTransform in
                    store.updatePlantedTransformByMemoryID(plantedID, transform: newTransform)
                }
            )
            .ignoresSafeArea()

            Text("Tap surface to plant 🌱 • Tap plant to open memory")
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.top, 16)
                .allowsHitTesting(false)
            if previewTransform != nil {
                HStack(spacing: 16) {
                    Button("Cancel") {
                        // remove preview
                        previewTransform = nil
                        previewPlantType = nil

                        // remove the memory we just created (so no orphan)
                        if let mem = pendingMemoryForPlacement {
                            store.deleteMemory(mem.id)
                        }
                        pendingMemoryForPlacement = nil
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())

                    Button("Place") {
                        confirmPlacement()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.green.opacity(0.8))
                    .clipShape(Capsule())
                }
                .padding(.top, 70)
            }
        }
        .task { store.load() }

        .sheet(isPresented: $showAdd) {
            AddMemoryView { memory in
                guard let t = pendingTransform else { return }

                
                store.addMemory(memory)

                pendingMemoryForPlacement = memory
                previewTransform = t
                previewPlantType = memory.plantType

                // close the sheet
                showAdd = false

                // clear pendingTransform used for this tap
                pendingTransform = nil
            }
        }

        .sheet(isPresented: $showMemory) {
            if let mem = selectedMemory {
                MemoryDetailView(memory: mem)
            } else {
                Text("Memory not found").padding()
            }
        }
    }
    private func confirmPlacement() {
        guard let t = previewTransform,
              let mem = pendingMemoryForPlacement else { return }

        let planted = PlantedMemory(id: UUID(), memoryID: mem.id, transform: t)
        store.addPlanted(planted)

        // clear preview state
        previewTransform = nil
        previewPlantType = nil
        pendingMemoryForPlacement = nil
    }
}
