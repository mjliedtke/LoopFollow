// LoopFollow
// PumpBatteryChange.swift

import Foundation

extension MainViewController {
    func processBage(entries: [bageData]) {
        if !entries.isEmpty {
            updateBage(data: entries)
        } else if let bage = currentBage {
            updateBage(data: [bage])
        } else if needsBageData {
            webLoadNSBage()
        }
    }

    /// The battery age backs both an info row and an alarm, so fetch it whenever
    /// either one needs it — gating on row visibility alone would leave the
    /// alarm without data for a user who only wants the alert.
    private var needsBageData: Bool {
        if Storage.shared.infoDisplayItems.value.isVisible(.bage) { return true }
        return Storage.shared.alarms.value.contains { $0.type == .batteryAge && $0.isEnabled }
    }
}
