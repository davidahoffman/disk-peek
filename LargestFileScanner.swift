import Foundation

enum LargestFileScanner {
    static func scan() throws -> LargestFile? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        // A bounded metadata query, not a recursive file-content scan. If a
        // candidate exists, every larger indexed file is included in this query.
        process.arguments = ["-0", "-onlyin", NSHomeDirectory(), "kMDItemFSSize >= 100000000"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        try process.run()
        let timeout = DispatchWorkItem {
            if process.isRunning { process.terminate() }
        }
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 20, execute: timeout)
        defer { timeout.cancel() }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "DiskPeek", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "The Spotlight search did not finish. Try again."])
        }
        let urls = data.split(separator: 0).compactMap { bytes -> URL? in
            guard let path = String(data: Data(bytes), encoding: .utf8) else { return nil }
            return URL(fileURLWithPath: path)
        }
        return largest(in: urls)
    }

    static func largest(in urls: [URL]) -> LargestFile? {
        urls.compactMap { url -> LargestFile? in
            guard let values = try? url.resourceValues(forKeys: [
                .isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey,
            ]), values.isRegularFile == true, values.isSymbolicLink != true,
                  let size = values.fileSize, size > 0 else { return nil }
            return LargestFile(path: url.path, bytes: Int64(size))
        }.max { left, right in
            left.bytes == right.bytes ? left.path > right.path : left.bytes < right.bytes
        }
    }
}
