import Foundation

@main
enum StorageTests {
    static func main() throws {
        let disk = try StorageSnapshot(name: "Test", total: 1000, free: 170)
        precondition(disk.used == 830 && disk.percent == 83 && disk.fraction == 0.83)
        let empty = try StorageSnapshot(name: "Empty", total: 100, free: 100)
        let full = try StorageSnapshot(name: "Full", total: 100, free: 0)
        precondition(empty.percent == 0)
        precondition(full.percent == 100)
        for (total, free): (Int64, Int64) in [(0, 0), (-1, 0), (100, -1), (100, 101)] {
            do {
                _ = try StorageSnapshot(name: "Invalid", total: total, free: free)
                fatalError("Invalid capacity was accepted")
            } catch { /* Expected. */ }
        }
        let live = try StorageSnapshot.read()
        precondition(live.total > 0 && (0...100).contains(live.percent))
        print("PASS: percentage, empty/full disk, four invalid readings, live capacity")
        print("Live: \(live.name), \(live.percent)% used, \(live.freeLabel) free / \(live.totalLabel)")
    }
}
