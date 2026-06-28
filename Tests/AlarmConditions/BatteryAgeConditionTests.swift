// LoopFollow
// BatteryAgeConditionTests.swift

@testable import LoopFollow
import Testing

struct BatteryAgeConditionTests {
    let cond = BatteryAgeCondition()

    @Test("fires when battery age exceeds threshold days")
    func firesWhenOlderThanThreshold() {
        let alarm = Alarm.batteryAge(threshold: 30)
        // Battery changed 31 days ago → older than 30-day threshold
        let insertTime = Date().addingTimeInterval(-31 * 86400).timeIntervalSince1970
        let data = AlarmData.withPumpBatteryInsertTime(insertTime)
        #expect(cond.evaluate(alarm: alarm, data: data, now: .init()))
    }

    @Test("does NOT fire before battery age reaches threshold days")
    func doesNotFireBeforeThreshold() {
        let alarm = Alarm.batteryAge(threshold: 30)
        // Battery changed 29 days ago → younger than 30-day threshold
        let insertTime = Date().addingTimeInterval(-29 * 86400).timeIntervalSince1970
        let data = AlarmData.withPumpBatteryInsertTime(insertTime)
        #expect(!cond.evaluate(alarm: alarm, data: data, now: .init()))
    }

    @Test("fires exactly at the threshold")
    func firesAtThreshold() {
        let alarm = Alarm.batteryAge(threshold: 10)
        // Battery changed 10 days and a minute ago → just past the 10-day mark
        let insertTime = Date().addingTimeInterval(-10 * 86400 - 60).timeIntervalSince1970
        let data = AlarmData.withPumpBatteryInsertTime(insertTime)
        #expect(cond.evaluate(alarm: alarm, data: data, now: .init()))
    }

    // MARK: - Edge cases

    @Test("does NOT fire when bageInsertTime is nil")
    func ignoresMissingBattery() {
        let alarm = Alarm.batteryAge(threshold: 30)
        let data = AlarmData.withPumpBatteryInsertTime(nil)
        #expect(!cond.evaluate(alarm: alarm, data: data, now: .init()))
    }

    @Test("does NOT fire when bageInsertTime is zero (no battery data)")
    func ignoresZeroInsertTime() {
        let alarm = Alarm.batteryAge(threshold: 30)
        let data = AlarmData.withPumpBatteryInsertTime(0)
        #expect(!cond.evaluate(alarm: alarm, data: data, now: .init()))
    }

    @Test("does NOT fire when threshold is nil")
    func ignoresNilThreshold() {
        let alarm = Alarm.batteryAge(threshold: nil)
        let insertTime = Date().addingTimeInterval(-40 * 86400).timeIntervalSince1970
        let data = AlarmData.withPumpBatteryInsertTime(insertTime)
        #expect(!cond.evaluate(alarm: alarm, data: data, now: .init()))
    }
}
