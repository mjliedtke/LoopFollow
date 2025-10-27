// LoopFollow
// ResumePump.swift

import Foundation

extension MainViewController {
    // NS Resume Pump Response Processor
    // This processes explicit "Resume Pump" treatment entries
    // If no explicit entries exist, temp basal detection handles it instead
    func processResumePump(entries: [[String: AnyObject]]) {
        // Only process if we have explicit resume pump entries
        // Otherwise, leave the data from temp basal detection intact
        guard !entries.isEmpty else {
            print("⏩ processResumePump: No explicit resume entries, keeping temp basal detections")
            return
        }

        print("🔍 processResumePump: Processing \(entries.count) explicit resume entries")
        resumeGraphData.removeAll()

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
                resumeGraphData.append(dot)
            }
        }

        if Storage.shared.graphOtherTreatments.value {
            updateResumeGraph()
        }
    }
}
