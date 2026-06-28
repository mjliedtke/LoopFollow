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

    /// Info items that can color their value yellow/red based on an "age in days"
    /// threshold (computed from the matching insert time). These are the items
    /// whose value represents time since the last change.
    var supportsAlertColors: Bool {
        switch self {
        case .sage, .cage, .bage:
            return true
        default:
            return false
        }
    }
}

/// Visual alert level for an info-table value. Drives the text color of the row.
enum InfoAlertSeverity: Int {
    case normal
    case warning // yellow
    case urgent // red
}

/// User-configurable yellow/red thresholds for an info-table item.
/// For age-based items the values are "days since change". Independent of
/// alarms — a configured threshold colors the row without any sound or notification.
struct InfoAlertThreshold: Codable, Equatable {
    var isEnabled: Bool = false
    /// Color the value yellow once the age reaches this many days.
    var warningDays: Double? = nil
    /// Color the value red once the age reaches this many days.
    var urgentDays: Double? = nil
}

enum InfoAlertEvaluator {
    /// Returns the severity for a given age (in days) against the configured threshold.
    /// Urgent (red) takes precedence over warning (yellow).
    static func severity(forDays days: Double, threshold: InfoAlertThreshold) -> InfoAlertSeverity {
        guard threshold.isEnabled else { return .normal }
        if let urgent = threshold.urgentDays, days >= urgent { return .urgent }
        if let warning = threshold.warningDays, days >= warning { return .warning }
        return .normal
    }
}
