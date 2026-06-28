// LoopFollow
// InfoAlertColorSettingsView.swift

import SwiftUI

/// Lets the user color individual info-table rows yellow/red once their value
/// passes a configurable level. Independent of alarms — no sound or notification
/// is involved, only the text color of the row changes.
struct InfoAlertColorSettingsView: View {
    @ObservedObject private var store = Storage.shared.infoAlertThresholds

    private let colorableTypes = InfoType.allCases.filter(\.supportsAlertColors)

    var body: some View {
        Form {
            Section {
                Text("Color an information-table row yellow or red once its value passes the configured level. This only changes the text color — it does not play an alarm sound or send a notification.")
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
        if let config = type.alertColorConfig {
            let threshold = binding(for: type)
            let isEnabled = threshold.wrappedValue.isEnabled
            let verb = config.direction == .fallingIsWorse ? "below" : "at"

            Section(
                header: Text(type.name),
                footer: isEnabled ? Text(footerText(for: config)) : nil
            ) {
                Toggle("Color this row", isOn: enabledBinding(threshold, config: config))

                if isEnabled {
                    Stepper(
                        "Yellow \(verb) \(format(threshold.wrappedValue.warningValue ?? config.defaultWarning, config: config))",
                        value: valueBinding(threshold, keyPath: \.warningValue, default: config.defaultWarning),
                        in: config.range,
                        step: config.step
                    )
                    Stepper(
                        "Red \(verb) \(format(threshold.wrappedValue.urgentValue ?? config.defaultUrgent, config: config))",
                        value: valueBinding(threshold, keyPath: \.urgentValue, default: config.defaultUrgent),
                        in: config.range,
                        step: config.step
                    )
                }
            }
        }
    }

    // MARK: - Formatting

    private func format(_ value: Double, config: InfoAlertColorConfig) -> String {
        let number = config.step.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
        return "\(number) \(config.unitLabel)"
    }

    private func footerText(for config: InfoAlertColorConfig) -> String {
        switch config.direction {
        case .risingIsWorse:
            return "Yellow shows first; red takes over at the higher value."
        case .fallingIsWorse:
            return "Yellow shows first; red takes over at the lower value."
        }
    }

    // MARK: - Bindings

    private func binding(for type: InfoType) -> Binding<InfoAlertThreshold> {
        Binding(
            get: { store.value[String(type.rawValue)] ?? InfoAlertThreshold() },
            set: { store.value[String(type.rawValue)] = $0 }
        )
    }

    private func enabledBinding(_ threshold: Binding<InfoAlertThreshold>, config: InfoAlertColorConfig) -> Binding<Bool> {
        Binding(
            get: { threshold.wrappedValue.isEnabled },
            set: { isOn in
                var updated = threshold.wrappedValue
                updated.isEnabled = isOn
                if isOn {
                    if updated.warningValue == nil { updated.warningValue = config.defaultWarning }
                    if updated.urgentValue == nil { updated.urgentValue = config.defaultUrgent }
                }
                threshold.wrappedValue = updated
            }
        )
    }

    private func valueBinding(
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
