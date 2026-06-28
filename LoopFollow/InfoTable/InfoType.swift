// LoopFollow
// InfoType.swift

import Foundation

enum InfoType: Int, CaseIterable {
    case iob, cob, basal, override, battery, pump, pumpBattery, sage, cage, recBolus, minMax, carbsToday, autosens, profile, target, isf, carbRatio, updated, tdd, iage, bage

    var name: String {
        switch self {
        case .iob: return "IOB"
        case .cob: return "COB"
        case .basal: return "Basal"
        case .override: return "Override"
        case .battery: return "Battery"
        case .pump: return "Pump"
        case .pumpBattery: return "Pump Battery"
        case .sage: return "SAGE"
        case .cage: return "CAGE"
        case .recBolus: return "Rec. Bolus"
        case .minMax: return "Min/Max"
        case .carbsToday: return "Carbs today"
        case .autosens: return "Autosens"
        case .profile: return "Profile"
        case .target: return "Target"
        case .isf: return "ISF"
        case .carbRatio: return "CR"
        case .updated: return "Updated"
        case .tdd: return "TDD"
        case .iage: return "IAGE"
        case .bage: return "BAGE"
        }
    }

    var defaultVisible: Bool {
        switch self {
        case .iob, .cob, .basal, .override, .battery, .pump, .sage, .cage, .recBolus, .minMax, .carbsToday:
            return true
        default:
            return false
        }
    }

    var sortOrder: Int {
        return rawValue
    }

    /// Color configuration for info items that can show yellow/red alerts.
    /// `nil` for items that don't support coloring. The thresholds are in the
    /// item's native unit (days for ages, U for insulin, g for carbs, % for batteries).
    var alertColorConfig: InfoAlertColorConfig? {
        switch self {
        // Age items (days since last change) — higher is worse.
        case .sage: return InfoAlertColorConfig(direction: .risingIsWorse, unitLabel: "days", range: 1 ... 30, step: 1, defaultWarning: 9, defaultUrgent: 10)
        case .cage: return InfoAlertColorConfig(direction: .risingIsWorse, unitLabel: "days", range: 1 ... 14, step: 1, defaultWarning: 2, defaultUrgent: 3)
        case .bage: return InfoAlertColorConfig(direction: .risingIsWorse, unitLabel: "days", range: 1 ... 90, step: 1, defaultWarning: 17, defaultUrgent: 22)
        // Insulin / carbs on board and recommended bolus — higher is worse.
        case .iob: return InfoAlertColorConfig(direction: .risingIsWorse, unitLabel: "U", range: 0 ... 50, step: 0.5, defaultWarning: 8, defaultUrgent: 12)
        case .cob: return InfoAlertColorConfig(direction: .risingIsWorse, unitLabel: "g", range: 0 ... 300, step: 5, defaultWarning: 60, defaultUrgent: 100)
        case .recBolus: return InfoAlertColorConfig(direction: .risingIsWorse, unitLabel: "U", range: 0 ... 25, step: 0.5, defaultWarning: 2, defaultUrgent: 4)
        // Reservoir / batteries — lower is worse.
        case .pump: return InfoAlertColorConfig(direction: .fallingIsWorse, unitLabel: "U", range: 0 ... 100, step: 1, defaultWarning: 20, defaultUrgent: 10)
        case .pumpBattery: return InfoAlertColorConfig(direction: .fallingIsWorse, unitLabel: "%", range: 0 ... 100, step: 5, defaultWarning: 30, defaultUrgent: 15)
        case .battery: return InfoAlertColorConfig(direction: .fallingIsWorse, unitLabel: "%", range: 0 ... 100, step: 5, defaultWarning: 30, defaultUrgent: 15)
        default: return nil
        }
    }

    /// Whether this item can show configurable yellow/red color alerts.
    var supportsAlertColors: Bool {
        alertColorConfig != nil
    }
}

/// Visual alert level for an info-table value. Drives the text color of the row.
enum InfoAlertSeverity: Int {
    case normal
    case warning // yellow
    case urgent // red
}

/// Which direction of a value is "worse" and should trigger coloring.
enum InfoAlertDirection {
    case risingIsWorse // color once value >= threshold (e.g. age, IOB, COB)
    case fallingIsWorse // color once value <= threshold (e.g. reservoir, battery)
}

/// Static per-item configuration describing how its color thresholds behave.
struct InfoAlertColorConfig {
    let direction: InfoAlertDirection
    let unitLabel: String
    let range: ClosedRange<Double>
    let step: Double
    let defaultWarning: Double
    let defaultUrgent: Double
}

/// User-configurable yellow/red thresholds for an info-table item, in the item's
/// native unit. Independent of alarms — a configured threshold colors the row
/// without any sound or notification.
struct InfoAlertThreshold: Codable, Equatable {
    var isEnabled: Bool = false
    /// Color the value yellow once it passes this value (direction-dependent).
    var warningValue: Double? = nil
    /// Color the value red once it passes this value (direction-dependent).
    var urgentValue: Double? = nil
}

enum InfoAlertEvaluator {
    /// Returns the severity for a value against the configured threshold and
    /// direction. Urgent (red) takes precedence over warning (yellow).
    static func severity(forValue value: Double, threshold: InfoAlertThreshold, direction: InfoAlertDirection) -> InfoAlertSeverity {
        guard threshold.isEnabled else { return .normal }
        switch direction {
        case .risingIsWorse:
            if let urgent = threshold.urgentValue, value >= urgent { return .urgent }
            if let warning = threshold.warningValue, value >= warning { return .warning }
        case .fallingIsWorse:
            if let urgent = threshold.urgentValue, value <= urgent { return .urgent }
            if let warning = threshold.warningValue, value <= warning { return .warning }
        }
        return .normal
    }
}
