import Foundation

@MainActor
final class MemoryStore: ObservableObject {
    @Published private(set) var memories: [Memory] = []
    @Published private(set) var planted: [PlantedMemory] = []

    private var memoriesURL: URL { documentsURL.appendingPathComponent("memories.json") }
    private var plantedURL: URL { documentsURL.appendingPathComponent("planted.json") }

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func load() {
        memories = loadJSON([Memory].self, from: memoriesURL) ?? []
        planted  = loadJSON([PlantedMemory].self, from: plantedURL) ?? []
    }
    
    func addMemory(_ memory: Memory) {
        memories.insert(memory, at: 0)
        save()
    }

    func addPlanted(_ p: PlantedMemory) {
        planted.append(p)
        save()
    }

    func save() {
        saveJSON(memories, to: memoriesURL)
        saveJSON(planted, to: plantedURL)
    }
    
    func deletePlantedByMemoryID(_ plantedID: UUID) {
        planted.removeAll { $0.id == plantedID }
        save()
    }
    
    func deleteMemory(_ id: UUID) {
        memories.removeAll { $0.id == id }
        save()
    }

    func updatePlantedTransformByMemoryID(_ plantedID: UUID, transform: [Float]) {
        guard let idx = planted.firstIndex(where: { $0.id == plantedID }) else { return }
        planted[idx].transform = transform
        save()
    }
    
    private func loadJSON<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try? dec.decode(T.self, from: data)
    }

    private func saveJSON<T: Encodable>(_ value: T, to url: URL) {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted]
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(value) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    
}
