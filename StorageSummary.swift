import SwiftUI

struct StorageSummary: View {
    let snapshot: StorageSnapshot?
    let fileScan: FileScan?

    private var tint: Color {
        guard let fraction = snapshot?.fraction else { return .secondary }
        return fraction >= 0.9 ? .red : fraction >= 0.8 ? .orange : .accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(snapshot?.name ?? "Startup disk", systemImage: "internaldrive")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            if let disk = snapshot {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(disk.percent)%")
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                    Text("used")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.10))
                        Capsule().fill(tint)
                            .frame(width: geometry.size.width * disk.fraction)
                    }
                }
                .frame(height: 7)
                .accessibilityLabel("Storage used")
                .accessibilityValue("\(disk.percent) percent")
                Text("\(disk.freeLabel) free")
                    .font(.system(size: 12))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                Text("Storage unavailable")
                    .font(.headline)
                Text("Open Disk Peek to retry.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if let file = fileScan?.recentFile() {
                HStack(spacing: 4) {
                    Text(file.name)
                        .truncationMode(.middle)
                    Text("· \(file.size)")
                        .monospacedDigit()
                        .fixedSize()
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Largest indexed file to review: \(file.name), \(file.size)")
                .help("Largest Spotlight-indexed file in your home folder. Review before deleting: \(file.path)")
            } else {
                Text("Find large files ›")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
