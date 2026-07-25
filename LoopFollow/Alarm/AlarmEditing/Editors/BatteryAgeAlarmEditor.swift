// LoopFollow
// BatteryAgeAlarmEditor.swift

import SwiftUI

struct BatteryAgeAlarmEditor: View {
    @Binding var alarm: Alarm

    private var maxAgeDays: Int {
        Int(alarm.threshold ?? 30)
    }

    var body: some View {
        Group {
            InfoBanner(
                text: "Alert me when the pump battery is older than \(maxAgeDays) days.",
                alarmType: alarm.type
            )

            AlarmGeneralSection(alarm: $alarm)

            AlarmStepperSection(
                header: "Maximum Battery Age",
                footer: "Trigger the alert once the time since the last " +
                    "pump battery change passes this many days.",
                title: "Battery Age",
                range: 1 ... 90,
                step: 1,
                unitLabel: "days",
                value: $alarm.threshold
            )

            AlarmActiveSection(alarm: $alarm)
            AlarmAudioSection(alarm: $alarm)
            AlarmSnoozeSection(alarm: $alarm)
        }
    }
}
