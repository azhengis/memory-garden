import SwiftUI
import RealityKit
import ARKit
import UIKit

struct ARContainerView: UIViewRepresentable {
    let planted: [PlantedMemory]
    let memories: [Memory]

    let previewTransform: [Float]?
    let previewPlantType: PlantType?

    let onSelectMemory: (UUID) -> Void
    let onRequestNewMemory: (_ transform: [Float], _ onMemoryCreated: @escaping (Memory) -> Void) -> Void

    let onConfirmPlacement: () -> Void
    let onCancelPlacement: () -> Void

    let onDeleteMemoryPlant: (UUID) -> Void
    let onMoveMemoryPlant: (UUID, [Float]) -> Void

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: context.coordinator,
                                                     action: #selector(Coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.45
        arView.addGestureRecognizer(longPress)
        tap.require(toFail: longPress)

        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        pan.isEnabled = false // only enabled during Move mode
        arView.addGestureRecognizer(pan)

        context.coordinator.arView = arView
        context.coordinator.pan = pan
        context.coordinator.onSelectMemory = onSelectMemory
        context.coordinator.onRequestNewMemory = onRequestNewMemory
        context.coordinator.onDeleteMemoryPlant = onDeleteMemoryPlant
        context.coordinator.onMoveMemoryPlant = onMoveMemoryPlant

        // initial load
        context.coordinator.syncPlanted(planted, memories: memories)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.syncPlanted(planted, memories: memories)
        context.coordinator.updatePreview(
            transform: previewTransform,
            plantType: previewPlantType
        )
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        weak var arView: ARView?
        weak var pan: UIPanGestureRecognizer?

        var onSelectMemory: ((UUID) -> Void)?
        var onRequestNewMemory: ((_ transform: [Float], _ onMemoryCreated: @escaping (Memory) -> Void) -> Void)?

        var onDeleteMemoryPlant: ((UUID) -> Void)?
        var onMoveMemoryPlant: ((UUID, [Float]) -> Void)?

        // keep anchors by memoryID so we can update/delete
        private var anchorByPlantedID: [UUID: AnchorEntity] = [:]
        private var previewAnchor: AnchorEntity?
        func updatePreview(transform: [Float]?, plantType: PlantType?) {
            guard let arView else { return }

            // Remove old preview
            previewAnchor?.removeFromParent()
            previewAnchor = nil

            guard let transform, let plantType else { return }

            let matrix = simd_float4x4.fromArray(transform)
            let anchor = AnchorEntity(world: matrix)

            let plant = PlantFactory.makePlant(type: plantType)

            // 👻 Ghost look
            func makeGhost(_ entity: Entity) {
                if let me = entity as? ModelEntity, var model = me.model {
                    model.materials = model.materials.map { _ in
                        SimpleMaterial(color: .white.withAlphaComponent(0.35), isMetallic: false)
                    }
                    me.model = model
                }
                for c in entity.children { makeGhost(c) }
            }
            makeGhost(plant)
            plant.components.set(InputTargetComponent())

            anchor.addChild(plant)
            arView.scene.addAnchor(anchor)

            previewAnchor = anchor
        }
        // Move mode state
        private var movingPlantedID: UUID?
        private var movingAnchor: AnchorEntity?

        func syncPlanted(_ planted: [PlantedMemory], memories: [Memory]) {
            guard let arView else { return }

            // Remove anchors for planted that no longer exist
            let currentPlantedIDs = Set(planted.map { $0.id })
            for (pid, anchor) in anchorByPlantedID {
                if !currentPlantedIDs.contains(pid) {
                    anchor.removeFromParent()
                    anchorByPlantedID.removeValue(forKey: pid)
                }
            }

            // Add or update anchors for each planted item
            for p in planted {
                guard let mem = memories.first(where: { $0.id == p.memoryID }) else { continue }

                let matrix = simd_float4x4.fromArray(p.transform)

                if let existing = anchorByPlantedID[p.id] {
                    existing.transform.matrix = matrix
                } else {
                    let anchor = AnchorEntity(world: matrix)
                    let plant = PlantFactory.makePlant(type: mem.plantType)

                    plant.components.set(MemoryIDComponent(idString: mem.id.uuidString))
                    plant.name = p.id.uuidString

                    anchor.addChild(plant)
                    arView.scene.addAnchor(anchor)

                    anchorByPlantedID[p.id] = anchor
                }
            }
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView else { return }
            let location = sender.location(in: arView)

            // Tap existing plant  - open memory
            if let entity = arView.entity(at: location),
               let memoryID = findMemoryID(upFrom: entity) {
                onSelectMemory?(memoryID)
                return
            }

            // Tap surface - new plant
            guard let result = arView.raycast(from: location,
                                             allowing: .estimatedPlane,
                                             alignment: .horizontal).first else {
                return
            }

            onRequestNewMemory?(result.worldTransform.toArray) { _ in }
        }

        // LONG PRESS: show Move/Delete
        @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
            guard sender.state == .began, let arView else { return }
            let location = sender.location(in: arView)

            guard let entity = arView.entity(at: location) else { return }

            guard let plantedID = findPlantedID(upFrom: entity),
                  let anchor = anchorByPlantedID[plantedID] else { return }

            showActionSheet(plantedID: plantedID, anchor: anchor)
        }
        
        private func findPlantedID(upFrom entity: Entity) -> UUID? {
            var current: Entity? = entity
            while let e = current {
                if let uuid = UUID(uuidString: e.name) { return uuid }
                current = e.parent
            }
            return nil
        }

        private func showActionSheet(plantedID: UUID, anchor: AnchorEntity) {
            guard let vc = presentingViewController() else { return }

            let sheet = UIAlertController(title: "Plant", message: nil, preferredStyle: .actionSheet)

            sheet.addAction(UIAlertAction(title: "Move", style: .default) { _ in
                self.startMove(plantedID: plantedID, anchor: anchor)
            })

            sheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                anchor.removeFromParent()
                self.anchorByPlantedID.removeValue(forKey: plantedID)
                self.onDeleteMemoryPlant?(plantedID) // ⚠️ now this UUID is plantedID
            })

            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            vc.present(sheet, animated: true)
        }

        private func startMove(plantedID: UUID, anchor: AnchorEntity) {
            movingPlantedID = plantedID
            movingAnchor = anchor
            pan?.isEnabled = true
        }

        @objc func handlePan(_ sender: UIPanGestureRecognizer) {
            guard let arView, let anchor = movingAnchor, let plantedID = movingPlantedID else { return }

            let location = sender.location(in: arView)

            switch sender.state {
            case .changed:
                if let hit = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal).first {
                    anchor.transform.matrix = hit.worldTransform
                }

            case .ended:
                let newTransform = anchor.transform.matrix.toArray
                onMoveMemoryPlant?(plantedID, newTransform) 
                movingPlantedID = nil
                movingAnchor = nil
                pan?.isEnabled = false

            case .cancelled, .failed:
                movingPlantedID = nil
                movingAnchor = nil
                pan?.isEnabled = false

            default: break
            }
        }
        
        // Walk up parents until we find MemoryIDComponent
        private func findMemoryID(upFrom entity: Entity) -> UUID? {
            var current: Entity? = entity
            while let e = current {
                if let comp = e.components[MemoryIDComponent.self],
                   let uuid = UUID(uuidString: comp.idString) {
                    return uuid
                }
                current = e.parent
            }
            return nil
        }

        private func presentingViewController() -> UIViewController? {
            guard let arView else { return nil }
            var vc = arView.window?.rootViewController
            while let presented = vc?.presentedViewController { vc = presented }
            return vc
        }
    }
}
