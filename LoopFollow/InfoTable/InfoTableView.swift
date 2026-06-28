// LoopFollow
// InfoTableView.swift

import SwiftUI

struct InfoTableView: View {
    @ObservedObject var infoManager: InfoManager
    var timeZoneOverride: String?

    @ScaledMetric(relativeTo: .body) private var fontSize: CGFloat = 17
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 21

    var body: some View {
        List {
            if let tz = timeZoneOverride {
                row(name: "Time Zone", value: tz, severity: .normal)
            }
            ForEach(infoManager.visibleRows) { item in
                row(name: item.name, value: item.value, severity: item.severity)
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, rowHeight)
    }

    /// Maps an alert severity to the value text color. Normal uses the default
    /// primary color; warning/urgent match the app's yellow/red convention.
    private func valueColor(for severity: InfoAlertSeverity) -> Color {
        switch severity {
        case .normal: return .primary
        case .warning: return .yellow
        case .urgent: return .red
        }
    }

    private func row(name: String, value: String, severity: InfoAlertSeverity) -> some View {
        // Show a placeholder for any field that has no value yet,
        // so the row reads as "no data" rather than appearing empty.
        let displayValue = value.isEmpty ? "—" : value
        let color = valueColor(for: severity)

        return ViewThatFits(in: .horizontal) {
            // Preferred: compact single line (label — value)
            HStack {
                Text(name)
                Spacer()
                Text(displayValue)
                    .foregroundStyle(color)
            }

            // Fallback when the single line won't fit: label over value
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                Text(displayValue)
                    .foregroundStyle(color)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .font(.system(size: fontSize))
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .frame(minHeight: rowHeight)
        .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
    }
}
