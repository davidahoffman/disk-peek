import Foundation

@main
enum SharedFilesTests {
    static func main() throws {
        let data = try JSONEncoder().encode(FileScan(date: Date(timeIntervalSince1970: 1),
            file: LargestFile(path: "/sample/movie.mov", bytes: 15_000_000_000), error: nil))
        let decoded = try JSONDecoder().decode(FileScan.self, from: data)
        precondition(decoded.file?.name == "movie.mov")
        precondition(decoded.file?.bytes == 15_000_000_000)
        precondition(decoded.recentFile(at: Date(timeIntervalSince1970: 2)) != nil)
        precondition(decoded.recentFile(at: Date(timeIntervalSince1970: 86_401)) == nil)
        precondition(decoded.recentFile(at: Date(timeIntervalSince1970: 0)) == nil)
        let failed = FileScan(date: .now, file: decoded.file, error: "Search failed")
        precondition(failed.recentFile() == nil)

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DiskPeekTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let small = directory.appendingPathComponent("small file.txt")
        let large = directory.appendingPathComponent("large\nfile.mov")
        let alias = directory.appendingPathComponent("alias")
        try Data(repeating: 1, count: 10).write(to: small)
        try Data(repeating: 1, count: 20).write(to: large)
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: large)
        let largest = LargestFileScanner.largest(in: [small, large, alias, directory,
            directory.appendingPathComponent("missing")])
        precondition(largest?.path == large.path && largest?.bytes == 20)
        precondition(LargestFileScanner.largest(in: []) == nil)
        precondition(LargestFileScanner.largest(in: [alias, directory]) == nil)
        print("PASS: cache encoding, stale/future/error rejection, file ranking, spaces/newlines, symlink/directory/missing/empty handling")
    }
}
