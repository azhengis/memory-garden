import RealityKit

enum PlantFactory {

    // Cache loaded models (no repeated loading)
    static var cache: [PlantType: ModelEntity] = [:]

    static func makePlant(type: PlantType) -> ModelEntity {

        // If already loaded then return clone instantly
        if let cached = cache[type] {
            return cached.clone(recursive: true)
        }

        // Load model first time
        let entity = try! ModelEntity.loadModel(named: modelName(for: type))

        let scale = scaleFor(type)
        entity.scale = SIMD3(repeating: scale)

        entity.position.y += yOffsetFor(type)

        entity.generateCollisionShapes(recursive: false)
        entity.components.set(InputTargetComponent())

        // Save to cache
        cache[type] = entity

        return entity.clone(recursive: true)
    }

    private static func scaleFor(_ type: PlantType) -> Float {
        switch type {
        case .daisy: return 0.00072
        case .tulip: return 0.00072
        case .sunflower: return 0.0072
        case .lavender: return 0.012
        case .lily: return 0.00072
        case .orchid: return 0.00072
        case .cactus: return 0.00072
        case .mushroom: return 0.00072
        case .crystal: return 0.00072
        default: return 0.00071
        }
    }

    private static func yOffsetFor(_ type: PlantType) -> Float {
        switch type {
        default: return 0.0
        }
    }

    private static func modelName(for type: PlantType) -> String {
        switch type {
        case .daisy: return "daisy"
        case .rose: return "rose"
        case .tulip: return "tulips"
        case .sunflower: return "sunflower"
        case .lavender: return "lavender"
        case .lily: return "lily"
        case .orchid: return "orchid"
        case .cactus: return "cactus"
        case .mushroom: return "mushroom"
        case .crystal: return "crystal"
        }
    }
}
