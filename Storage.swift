import Foundation

struct StorageSnapshot: Codable, Sendable {
    let name: String
    let total: Int64
    let free: Int64

    init(name: String, total: Int64, free: Int64) throws {
        guard total > 0, free >= 0, free <= total else {
            throw NSError(domain: "DiskPeek", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid disk-capacity reading."])
        }
        self.name = name
        self.total = total
        self.free = free
    }

    var used: Int64 { total - free }
    var fraction: Double { Double(used) / Double(total) }
    var percent: Int { Int((fraction * 100).rounded()) }
    var freeLabel: String { Self.format(free) }
    var totalLabel: String { Self.format(total) }

    static func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .decimal)
    }

    static func read() throws -> StorageSnapshot {
        // Home is on the writable Data volume. Its free space is shared by the
        // APFS container; subtracting it from capacity includes the other volumes.
        let volume = try URL(fileURLWithPath: NSHomeDirectory()).resourceValues(
            forKeys: [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey])
        guard let total = volume.volumeTotalCapacity,
              let free = volume.volumeAvailableCapacity else {
            throw NSError(domain: "DiskPeek", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Disk capacity is unavailable."])
        }
        return try StorageSnapshot(name: volume.volumeName ?? "Startup disk",
                                   total: Int64(total), free: Int64(free))
    }
}
