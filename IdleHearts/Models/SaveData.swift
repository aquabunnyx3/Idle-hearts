import Foundation

/// Everything that persists between launches. Kept as plain Codable so the
/// save file is small, versioned, and easy to migrate.
struct SaveData: Codable {
    var version = 1
    var chemistry: Double = 0
    var lifetimeChemistry: Double = 0
    var loveNotes: Double = 0
    var lifetimeLoveNotes: Double = 0
    var drama: Int = 0
    var heartGems: Int = 10
    var dateIndex: Int = 0
    var dateProgress: Double = 0
    var totalTaps: Int = 0
    var upgradeLevels: [String: Int] = [:]
    var employeeLevels: [String: Int] = [:]
    var departmentLevels: [String: Int] = [:]
    var affection: [String: Int] = [:]
    var journal: [JournalEntry] = []
    var sparkEndsAt: Date = .distantPast
    var sparkReadyAt: Date = .distantPast
    var rushEndsAt: Date = .distantPast
    var rushReadyAt: Date = .distantPast
    var soundEnabled = true
    var hapticsEnabled = true
    var hasSeenIntro = false
    var lastActive: Date = Date()
}

struct JournalEntry: Codable, Identifiable, Hashable {
    enum Kind: String, Codable { case date, drama, story }
    var id = UUID()
    var kind: Kind
    var title: String
    var detail: String
    var timestamp: Date
    var characters: [CharacterID]
}

enum SaveManager {
    private static var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("idlehearts-save.json")
    }

    static func load() -> SaveData? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(SaveData.self, from: data)
    }

    static func save(_ save: SaveData) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let data = try? encoder.encode(save) else { return }
        try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    static func erase() {
        try? FileManager.default.removeItem(at: url)
    }
}
