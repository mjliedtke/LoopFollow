// LoopFollow
// Basals.swift

import Foundation

extension MainViewController {
    // NS Temp Basal Response Processor
    func processNSBasals(entries: [[String: AnyObject]]) {
        infoManager.clearInfoData(type: .basal)

        basalData.removeAll()

        var lastEndDot = 0.0

        var tempArray = entries
        tempArray.reverse()

        for i in 0 ..< tempArray.count {
            guard let currentEntry = tempArray[i] as [String: AnyObject]? else { continue }

            // Decide which field to parse
            let dateString = currentEntry["timestamp"] as? String
                ?? currentEntry["created_at"] as? String
            guard let rawDateStr = dateString,
                  let dateParsed = NightscoutUtils.parseDate(rawDateStr)
            else {
                continue
            }

            let dateTimeStamp = dateParsed.timeIntervalSince1970
            guard let basalRate = currentEntry["absolute"] as? Double else {
                continue
            }

            let duration = currentEntry["duration"] as? Double ?? 0.0

            if i > 0 {
                let priorEntry = tempArray[i - 1] as [String: AnyObject]?
                let priorDateStr = priorEntry?["timestamp"] as? String
                    ?? priorEntry?["created_at"] as? String
                if let rawPrior = priorDateStr,
                   let priorDateParsed = NightscoutUtils.parseDate(rawPrior)
                {
                    let priorDateTimeStamp = priorDateParsed.timeIntervalSince1970
                    let priorDuration = priorEntry?["duration"] as? Double ?? 0.0

                    if (dateTimeStamp - priorDateTimeStamp) > (priorDuration * 60) + 15 {
                        var scheduled = 0.0
                        var midGap = false
                        var midGapTime: TimeInterval = 0
                        var midGapValue: Double = 0

                        for b in 0 ..< basalScheduleData.count {
                            let priorEnd = priorDateTimeStamp + (priorDuration * 60)
                            if priorEnd >= basalScheduleData[b].date {
                                scheduled = basalScheduleData[b].basalRate
                                if b < basalScheduleData.count - 1 {
                                    if dateTimeStamp > basalScheduleData[b + 1].date {
                                        midGap = true
                                        midGapTime = basalScheduleData[b + 1].date
                                        midGapValue = basalScheduleData[b + 1].basalRate
                                    }
                                }
                            }
                        }

                        let startDot = basalGraphStruct(basalRate: scheduled,
                                                        date: priorDateTimeStamp + (priorDuration * 60))
                        basalData.append(startDot)

                        if midGap {
                            let endDot1 = basalGraphStruct(basalRate: scheduled, date: midGapTime)
                            basalData.append(endDot1)
                            let startDot2 = basalGraphStruct(basalRate: midGapValue, date: midGapTime)
                            basalData.append(startDot2)
                            let endDot2 = basalGraphStruct(basalRate: midGapValue, date: dateTimeStamp)
                            basalData.append(endDot2)
                        } else {
                            let endDot = basalGraphStruct(basalRate: scheduled, date: dateTimeStamp)
                            basalData.append(endDot)
                        }
                    }
                }
            }

            // Start dot
            let startDot = basalGraphStruct(basalRate: basalRate, date: dateTimeStamp)
            basalData.append(startDot)

            // End dot
            var lastDot = dateTimeStamp + (duration * 60)
            if i == tempArray.count - 1, duration == 0.0 {
                lastDot = dateTimeStamp + (30 * 60)
            }
            latestBasal = Localizer.formatToLocalizedString(basalRate, maxFractionDigits: 2, minFractionDigits: 0)

            // Overlap check
            if i < tempArray.count - 1 {
                let nextEntry = tempArray[i + 1] as [String: AnyObject]?
                let nextDateStr = nextEntry?["timestamp"] as? String
                    ?? nextEntry?["created_at"] as? String
                if let rawNext = nextDateStr,
                   let nextDateParsed = NightscoutUtils.parseDate(rawNext)
                {
                    let nextDateTimeStamp = nextDateParsed.timeIntervalSince1970
                    if nextDateTimeStamp < (dateTimeStamp + (duration * 60)) {
                        lastDot = nextDateTimeStamp
                    }
                }
            }

            let endDot = basalGraphStruct(basalRate: basalRate, date: lastDot)
            basalData.append(endDot)
            lastEndDot = lastDot
        }

        // If last basal was prior to right now, we need to create one last scheduled entry
        if lastEndDot <= dateTimeUtils.getNowTimeIntervalUTC() {
            var scheduled = 0.0
            for b in 0 ..< basalProfile.count {
                let scheduleTimeToday = basalProfile[b].timeAsSeconds
                    + dateTimeUtils.getTimeIntervalMidnightToday()
                if lastEndDot >= scheduleTimeToday {
                    scheduled = basalProfile[b].value
                }
            }

            latestBasal = Localizer.formatToLocalizedString(scheduled,
                                                            maxFractionDigits: 2,
                                                            minFractionDigits: 0)

            let startDot = basalGraphStruct(basalRate: scheduled, date: lastEndDot)
            basalData.append(startDot)

            let endDot = basalGraphStruct(basalRate: scheduled,
                                          date: Date().timeIntervalSince1970 + (60 * 10))
            basalData.append(endDot)
        }

        if Storage.shared.graphBasal.value {
            updateBasalGraph()
        }

        if let profileBasal = profileManager.currentBasal(),
           profileBasal != latestBasal
        {
            latestBasal = "\(profileBasal) → \(latestBasal)"
        }
        infoManager.updateInfoData(type: .basal, value: latestBasal)

        // Extract suspend/resume events from temp basals
        // Only do this if no explicit suspend/resume events were found in treatments
        // This allows the code to work with both explicit "Suspend Pump" events
        // and implicit suspend events (0-rate temp basals)
        if suspendGraphData.isEmpty && resumeGraphData.isEmpty {
            extractSuspendResumeFromBasals(entries: entries)
        }
    }

    // Extract suspend and resume events from temp basal data
    // Look for temp basals with "suspend" in the reason field
    func extractSuspendResumeFromBasals(entries: [[String: AnyObject]]) {
        suspendGraphData.removeAll()
        resumeGraphData.removeAll()

        var lastFoundIndex = 0

        // Sort entries by timestamp (oldest first)
        var sortedEntries = entries.sorted { entry1, entry2 in
            let date1Str = entry1["timestamp"] as? String ?? entry1["created_at"] as? String ?? ""
            let date2Str = entry2["timestamp"] as? String ?? entry2["created_at"] as? String ?? ""

            guard let date1 = NightscoutUtils.parseDate(date1Str),
                  let date2 = NightscoutUtils.parseDate(date2Str) else {
                return false
            }

            return date1 < date2
        }

        for i in 0 ..< sortedEntries.count {
            guard let currentEntry = sortedEntries[i] as [String: AnyObject]?,
                  let dateStr = currentEntry["timestamp"] as? String ?? currentEntry["created_at"] as? String,
                  let parsedDate = NightscoutUtils.parseDate(dateStr) else {
                continue
            }

            // Check if this temp basal has "suspend" in the reason field
            let reason = currentEntry["reason"] as? String ?? ""
            guard reason.lowercased().contains("suspend") else {
                continue
            }

            let dateTimeStamp = parsedDate.timeIntervalSince1970
            let duration = currentEntry["duration"] as? Double ?? 0.0

            // This is a suspend event - add to suspend graph data
            let sgv = findNearestBGbyTime(needle: dateTimeStamp, haystack: bgData, startingIndex: lastFoundIndex)
            lastFoundIndex = sgv.foundIndex

            if dateTimeStamp < (dateTimeUtils.getNowTimeIntervalUTC() + (60 * 60)) {
                let suspendDot = DataStructs.timestampOnlyStruct(date: Double(dateTimeStamp), sgv: Int(sgv.sgv))
                suspendGraphData.append(suspendDot)
            }

            // Calculate resume time (when suspension duration expires)
            let resumeTime = dateTimeStamp + (duration * 60)

            // Add resume event if it's in the visible time range
            if resumeTime < (dateTimeUtils.getNowTimeIntervalUTC() + (60 * 60)) {
                let resumeSgv = findNearestBGbyTime(needle: resumeTime, haystack: bgData, startingIndex: lastFoundIndex)
                lastFoundIndex = resumeSgv.foundIndex

                let resumeDot = DataStructs.timestampOnlyStruct(date: Double(resumeTime), sgv: Int(resumeSgv.sgv))
                resumeGraphData.append(resumeDot)
            }
        }

        // Update graphs if the setting is enabled
        if Storage.shared.graphOtherTreatments.value {
            updateSuspendGraph()
            updateResumeGraph()
        }
    }
}
