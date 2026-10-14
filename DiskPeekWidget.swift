import WidgetKit
import SwiftUI

struct StorageEntry: TimelineEntry {
    let date: Date
    let snapshot: StorageSnapshot?
    let fileScan: FileScan?
}

struct StorageProvider: TimelineProvider {
    func placeholder(in context: Context) -> StorageEntry {
        StorageEntry(date: .now, snapshot: nil, fileScan: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (StorageEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StorageEntry>) -> Void) {
        let entry = readEntry()
        // This is a request, not a promised cadence. WidgetKit owns the budget.
        completion(Timeline(entries: [entry], policy: .after(entry.date.addingTimeInterval(15 * 60))))
    }

    private func readEntry() -> StorageEntry {
        StorageEntry(date: .now, snapshot: try? StorageSnapshot.read(), fileScan: SharedFiles.load())
    }
}

struct StorageWidget: Widget {
    let kind = "DiskPeekStorage"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StorageProvider()) { entry in
            StorageSummary(snapshot: entry.snapshot, fileScan: entry.fileScan)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "diskpeek://review"))
        }
        .configurationDisplayName("Disk Peek")
        .description("Startup-disk usage and free space, at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct DiskPeekWidgets: WidgetBundle {
    var body: some Widget { StorageWidget() }
}
