// LoopFollow
// InfoManager.swift

import Combine
import Foundation
import HealthKit

class InfoManager: ObservableObject {
    @Published var tableData: [InfoData]

    init() {
        tableData = InfoType.allCases.map { InfoData(id: $0.rawValue, name: $0.name) }
    }

    func updateInfoData(type: InfoType, value: String) {
        tableData[type.rawValue].value = value
        objectWillChange.send()
    }

    func updateInfoData(type: InfoType, value: HKQuantity) {
        let formattedValue = Localizer.formatQuantity(value)
        updateInfoData(type: type, value: formattedValue)
    }

    func updateInfoData(type: InfoType, firstValue: HKQuantity, secondValue: HKQuantity, separator: InfoDataSeparator) {
        let formattedFirstValue = Localizer.formatQuantity(firstValue)
        let formattedSecondValue = Localizer.formatQuantity(secondValue)
        if formattedFirstValue != formattedSecondValue {
            let combinedValue = "\(formattedFirstValue) \(separator.rawValue) \(formattedSecondValue)"
            updateInfoData(type: type, value: combinedValue)
        } else {
            updateInfoData(type: type, value: formattedFirstValue)
        }
    }

    func updateInfoData(type: InfoType, value: Double, maxFractionDigits: Int = 1, minFractionDigits: Int = 0) {
        let formattedValue = Localizer.formatToLocalizedString(value, maxFractionDigits: maxFractionDigits, minFractionDigits: minFractionDigits)
        updateInfoData(type: type, value: formattedValue)
    }

    func updateInfoData(type: InfoType, value: Double, enactedValue: Double, separator: InfoDataSeparator, maxFractionDigits: Int = 1, minFractionDigits: Int = 0) {
        let formattedValue = Localizer.formatToLocalizedString(value, maxFractionDigits: maxFractionDigits, minFractionDigits: minFractionDigits)
        let formattedEnactedValue = Localizer.formatToLocalizedString(enactedValue, maxFractionDigits: maxFractionDigits, minFractionDigits: minFractionDigits)
        let separatorString = separator.rawValue
        let combinedValue = "\(formattedValue) \(separatorString) \(formattedEnactedValue)"
        updateInfoData(type: type, value: combinedValue)
    }

    func updateInfoData(type: InfoType, value: Metric) {
        let formattedValue = value.formattedValue()
        updateInfoData(type: type, value: formattedValue)
    }

    func clearInfoData(type: InfoType) {
        tableData[type.rawValue].value = ""
        tableData[type.rawValue].severity = .normal
        objectWillChange.send()
    }

    func clearInfoData(types: [InfoType]) {
        for type in types {
            tableData[type.rawValue].value = ""
            tableData[type.rawValue].severity = .normal
        }
        objectWillChange.send()
    }

    /// Sets the visual alert level (yellow/red) for an info-table row.
    func setSeverity(type: InfoType, severity: InfoAlertSeverity) {
        tableData[type.rawValue].severity = severity
        objectWillChange.send()
    }

    /// Computes and applies the severity for an item from its configured
    /// yellow/red thresholds and direction. No-op (normal) when not configured.
    func updateInfoSeverity(type: InfoType, value: Double) {
        guard let config = type.alertColorConfig else { return }
        let threshold = Storage.shared.infoAlertThresholds.value[String(type.rawValue)] ?? InfoAlertThreshold()
        setSeverity(type: type, severity: InfoAlertEvaluator.severity(forValue: value, threshold: threshold, direction: config.direction))
    }

    var visibleRows: [InfoData] {
        Storage.shared.infoSort.value
            .filter { $0 < Storage.shared.infoVisible.value.count && Storage.shared.infoVisible.value[$0] }
            .compactMap { index in
                guard index < tableData.count else { return nil }
                return tableData[index]
            }
    }
}
