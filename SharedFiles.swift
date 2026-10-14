import Foundation

struct LargestFile: Codable, Sendable {
    let path: String
    let bytes: Int64
    var name: String { URL(fileURLWithPath: path).lastPathComponent }
    var size: String { StorageSnapshot.format(bytes) }
}

struct FileScan: Codable, Sendable {
    let date: Date
    let file: LargestFile?
    let error: String?

    func recentFile(at now: Date = .now) -> LargestFile? {
        guard error == nil, now.timeIntervalSince(date) >= 0,
              now.timeIntervalSince(date) < 24 * 60 * 60 else { return nil }
        return file
    }
}

enum SharedFiles {
    static let domain = "local.david.disk-peek"
    private static let key = "largestIndexedFile"
    private static var preferences: UserDefaults? {
        // Foundation disallows opening one's own application domain as a suite.
        Bundle.main.bundleIdentifier == domain ? .standard : UserDefaults(suiteName: domain)
    }

    static func load() -> FileScan? {
        guard let data = preferences?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(FileScan.self, from: data)
    }

    static func save(_ scan: FileScan) throws {
        guard let preferences else {
            throw NSError(domain: "DiskPeek", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Widget preferences are unavailable."])
        }
        preferences.set(try JSONEncoder().encode(scan), forKey: key)
        guard preferences.synchronize() else {
            throw NSError(domain: "DiskPeek", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Could not save the file result for the widget."])
        }
    }
}
