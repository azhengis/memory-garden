import Foundation
import simd

// MARK: - Media Type

enum MemoryMediaType: String, Codable, CaseIterable {
    case text
    case photo
    case video
    case audio
}

// MARK: - Memory

struct Memory: Identifiable, Codable {
    let id: UUID
    var title: String
    var createdAt: Date

    var mediaType: MemoryMediaType
    var text: String?
    var fileName: String?
    var plantType: PlantType
}

enum PlantType: String, Codable, CaseIterable {
    case daisy, rose, tulip, sunflower
    case lavender, lily
    case cactus, mushroom, orchid, crystal

    var name: String {
        switch self {
        case .daisy: return "Daisy"
        case .rose: return "Rose"
        case .tulip: return "Tulip"
        case .sunflower: return "Sunflower"
        case .lavender: return "Lavender"
        case .lily: return "Lily"
        case .orchid: return "Lotus"
        case .cactus: return "Cactus"
        case .mushroom: return "Mushroom"
        case .crystal: return "Crystal"
        }
    }

    var emoji: String {
        switch self {
        case .daisy: return "🌼"
        case .rose: return "🌹"
        case .tulip: return "🌷"
        case .sunflower: return "🌻"
        case .lavender: return "💜"
        case .lily: return "🪷"
        case .orchid: return "🪷"
        case .cactus: return "🌵"
        case .mushroom: return "🍄"
        case .crystal: return "💎"
        }
    }
}

// MARK: - Planted Memory (AR placement)

struct PlantedMemory: Identifiable, Codable {
    let id: UUID
    let memoryID: UUID
    var transform: [Float]
}

// MARK: - Transform Helpers

extension simd_float4x4 {
    var toArray: [Float] {
        [
            columns.0.x, columns.0.y, columns.0.z, columns.0.w,
            columns.1.x, columns.1.y, columns.1.z, columns.1.w,
            columns.2.x, columns.2.y, columns.2.z, columns.2.w,
            columns.3.x, columns.3.y, columns.3.z, columns.3.w
        ]
    }

    static func fromArray(_ a: [Float]) -> simd_float4x4 {
        precondition(a.count == 16)
        return simd_float4x4(
            SIMD4(a[0], a[1], a[2], a[3]),
            SIMD4(a[4], a[5], a[6], a[7]),
            SIMD4(a[8], a[9], a[10], a[11]),
            SIMD4(a[12], a[13], a[14], a[15])
        )
    }
}
