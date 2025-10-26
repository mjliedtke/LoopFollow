// LoopFollow
// PumpBatteryChange.swift

import Foundation

extension MainViewController {
    func processBage(entries: [bageData]) {
        if !entries.isEmpty {
            updateBage(data: entries)
        } else if let bage = currentBage {
            updateBage(data: [bage])
        } else if Storage.shared.infoVisible.value[InfoType.bage.rawValue] {
            webLoadNSBage()
        }
    }
}
