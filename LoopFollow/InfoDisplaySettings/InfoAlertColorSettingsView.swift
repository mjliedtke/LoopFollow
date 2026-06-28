// LoopFollow
// InfoAlertColorSettingsView.swift

import SwiftUI

/// Lets the user color individual info-table rows yellow/red once they pass a
/// configurable age (in days). Independent of alarms — no sound or notification
/// is involved, only the text color of the row changes.
struct InfoAlertColorSettingsView: View {
    @ObservedObject private var store = Storage.shared.infoAlertThresholds

    private let colorableTypes = InfoType.allCases.filter(\.supportsAlertColors)

    var body: some View {
        Form {
            Section {
                Text("Color an information-table row yellow or red once it passes the configured age. This only changes the text color — it does not play an alarm sound or send a notification.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(colorableTypes, id: \.self) { type in
                section(for: type)
            }
        }
        .preferredColorScheme(Storage.shared.appearanceMode.value.colorScheme)
        .navigationBarTitle("Information Table Alerts", displayMode: .inline)
        .onDisappear {
            // Trigger a refresh so the info table re-evaluates colors with the new thresholds.
            NotificationCenter.default.post(name: NSNotification.Name("refresh"), object: nil)
        }
    }

    @ViewBuilder
    private func section(for type: InfoType) -> some View {
        let threshold = binding(for: type)
        let isEnabled = threshold.wrappedValue.isEnabled

        Section(
            header: Text(type.name),
            footer: isEnabled
                ? Text("Yellow shows first; red takes over at the higher age.")
                : nil
        ) {
            Toggle("Color this row", isOn: Binding(
                get: { threshold.wrappedValue.isEnabled },
                set: { isOn in
                    var updated = threshold.wrappedValue
                    updated.isEnabled = isOn
                    if isOn {
                        if updated.warningDays == nil { updated.warningDays = 14 }
                        if updated.urgentDays == nil { updated.urgentDays = 21 }
                    }
                    threshold.wrappedValue = updated
                }
            ))

            if isEnabled {
                Stepper(
                    "Yellow at \(Int(threshold.wrappedValue.warningDays ?? 14)) days",
                    value: dayBinding(threshold, keyPath: \.warningDays, default: 14),
                    in: 1 ... 60
                )
                Stepper(
                    "Red at \(Int(threshold.wrappedValue.urgentDays ?? 21)) days",
                    value: dayBinding(threshold, keyPath: \.urgentDays, default: 21),
                    in: 1 ... 60
                )
            }
        }
    }

    private func binding(for type: InfoType) -> Binding<InfoAlertThreshold> {
        Binding(
            get: { store.value[String(type.rawValue)] ?? InfoAlertThreshold() },
            set: { store.value[String(type.rawValue)] = $0 }
        )
    }

    private func dayBinding(
        _ threshold: Binding<InfoAlertThreshold>,
        keyPath: WritableKeyPath<InfoAlertThreshold, Double?>,
        default def: Double
    ) -> Binding<Double> {
        Binding(
            get: { threshold.wrappedValue[keyPath: keyPath] ?? def },
            set: { newValue in
                var updated = threshold.wrappedValue
                updated[keyPath: keyPath] = newValue
                threshold.wrappedValue = updated
            }
        )
    }
}
