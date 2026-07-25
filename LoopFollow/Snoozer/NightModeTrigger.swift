// LoopFollow
// NightModeTrigger.swift

import Foundation

/// When the Snoozer's night mode may engage.
///
/// `.scheduled` reuses the day/night window already configured for alarms
/// (`AlarmConfiguration.dayStart` / `.nightStart`) rather than introducing a
/// second schedule to keep in sync.
enum NightModeTrigger: String, CaseIterable, Codable {
    case off
    case scheduled
    case always

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .scheduled: return "Scheduled"
        case .always: return "Always"
        }
    }
}
