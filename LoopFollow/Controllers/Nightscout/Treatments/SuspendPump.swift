// LoopFollow
// SuspendPump.swift

import Foundation

extension MainViewController {
    // NS Suspend Pump Response Processor
    // This processes explicit "Suspend Pump" treatment entries
    // If no explicit entries exist, temp basal detection handles it instead
    func processSuspendPump(entries: [[String: AnyObject]]) {
        // Only process if we have explicit suspend pump entries
        // Otherwise, leave the data from temp basal detection intact
        guard !entries.isEmpty else {
            print("⏩ processSuspendPump: No explicit suspend entries, keeping temp basal detections")
            return
        }

        print("🔍 processSuspendPump: Processing \(entries.count) explicit suspend entries")
        suspendGraphData.removeAll()

        var lastFoundIndex = 0

        for currentEntry in entries.reversed() {
            guard let dateStr = currentEntry["timestamp"] as? String ?? currentEntry["created_at"] as? String else { continue }

            guard let parsedDate = NightscoutUtils.parseDate(dateStr) else {
                continue
            }

            let dateTimeStamp = parsedDate.timeIntervalSince1970
            let sgv = findNearestBGbyTime(needle: dateTimeStamp, haystack: bgData, startingIndex: lastFoundIndex)
            lastFoundIndex = sgv.foundIndex

            if dateTimeStamp < (dateTimeUtils.getNowTimeIntervalUTC() + (60 * 60)) {
                let dot = DataStructs.timestampOnlyStruct(date: Double(dateTimeStamp), sgv: Int(sgv.sgv))
                suspendGraphData.append(dot)
            }
        }

        if Storage.shared.graphOtherTreatments.value {
            updateSuspendGraph()
        }
    }
}
