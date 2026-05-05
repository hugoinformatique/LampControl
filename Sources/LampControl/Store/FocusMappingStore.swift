import Foundation

final class FocusMappingStore {
    private let fileName = "focusMappings.json"

    func saveMappings(_ mappings: [FocusMapping]) throws {
        let data = try JSONEncoder().encode(mappings)
        try data.write(to: mappingsURL, options: .atomic)
    }

    func loadMappings() -> [FocusMapping] {
        guard FileManager.default.fileExists(atPath: mappingsURL.path) else { return [] }
        guard let data = try? Data(contentsOf: mappingsURL) else { return [] }
        if let decoded = try? JSONDecoder().decode([FocusMapping].self, from: data) {
            return decoded
        }
        return []
    }

    private var mappingsURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LampControl", isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory.appendingPathComponent(fileName)
    }
}
