import SwiftUI
import WidgetKit

@main
struct DiskPeekApp: App {
    var body: some Scene {
        Window("Disk Peek", id: "setup") {
            SetupView()
        }
        .windowResizability(.contentSize)
    }
}

struct SetupView: View {
    @State private var snapshot: StorageSnapshot?
    @State private var error: String?
    @State private var fileScan = SharedFiles.load()
    @State private var scanning = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            StorageSummary(snapshot: snapshot, fileScan: fileScan)
                .frame(height: 142)
            Divider()
            Text("Add it to your desktop")
                .font(.headline)
            Text("Right-click your desktop, choose Edit Widgets, then search for Disk Peek. Pick the small or medium widget.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("The widget works while this app is closed. macOS decides when to refresh it.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Divider()
            Text("Largest file to inspect")
                .font(.headline)
            Text("Searches Spotlight-indexed files over 100 MB in your home folder. Hidden, protected, or unindexed files may be missing. File size does not mean it is safe to delete or that all its space can be reclaimed.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let scan = fileScan, let file = scan.file {
                Text(file.path)
                    .font(.caption)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(file.size). Last scan: \(scan.date.formatted(date: .abbreviated, time: .shortened)).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if fileScan != nil, fileScan?.error == nil {
                Text("No indexed files over 100 MB were found.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Button(scanning ? "Searching…" : "Rescan files") {
                    Task { await scanFiles() }
                }
                .disabled(scanning)
                Spacer()
                Button("Reveal in Finder") { revealLargest() }
                    .disabled(fileScan?.file == nil)
            }
            if let error {
                Text(error).font(.callout).foregroundStyle(.red)
            }
            HStack {
                Button("Refresh widgets") { refresh() }
                Spacer()
                Button("Storage settings") { openStorage() }
            }
        }
        .padding(28)
        .frame(width: 380)
        .task {
            refresh()
            if fileScan?.recentFile() == nil { await scanFiles() }
        }
        .onOpenURL { url in
            if url.scheme == "diskpeek", url.host == "storage" { openStorage() }
            if url.scheme == "diskpeek", url.host == "review" {
                if fileScan?.recentFile() != nil { revealLargest() }
                else { Task { await scanFiles() } }
            }
        }
    }

    private func refresh() {
        do {
            snapshot = try StorageSnapshot.read()
            error = nil
        } catch {
            snapshot = nil
            self.error = error.localizedDescription
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "DiskPeekStorage")
    }

    private func openStorage() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.settings.Storage") {
            NSWorkspace.shared.open(url)
        }
    }

    @MainActor
    private func scanFiles() async {
        guard !scanning else { return }
        scanning = true
        defer { scanning = false }
        let result = await Task.detached(priority: .utility) { () -> FileScan in
            do {
                return FileScan(date: .now, file: try LargestFileScanner.scan(), error: nil)
            } catch {
                return FileScan(date: .now, file: nil, error: error.localizedDescription)
            }
        }.value
        do {
            try SharedFiles.save(result)
            fileScan = result
            error = result.error
        } catch {
            self.error = error.localizedDescription
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "DiskPeekStorage")
    }

    private func revealLargest() {
        guard let file = fileScan?.recentFile() else {
            error = "Rescan before reviewing this file."
            return
        }
        let url = URL(fileURLWithPath: file.path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            error = "That file has moved or been removed. Rescan to update the widget."
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
