// LoopFollow
// BatteryAgeCondition.swift

import Foundation

/// Fires when the pump battery's age (time since the last
/// "Pump Battery Change") exceeds the configured number of days.
struct BatteryAgeCondition: AlarmCondition {
    static let type: AlarmType = .batteryAge
    init() {}

    func evaluate(alarm: Alarm, data: AlarmData, now: Date) -> Bool {
        // 0. basic guards
        guard let maxAgeDays = alarm.threshold, maxAgeDays > 0 else { return false }
        guard let insertTS = data.bageInsertTime, insertTS > 0 else { return false }

        // convert UNIX timestamp to Date
        let insertedAt = Date(timeIntervalSince1970: insertTS)

        // 1. compute the moment the battery reaches the configured age
        let maxAge: TimeInterval = maxAgeDays * 24 * 60 * 60
        let trigger = insertedAt.addingTimeInterval(maxAge)

        return now >= trigger
    }
}
