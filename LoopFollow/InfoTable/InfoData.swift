// LoopFollow
// InfoData.swift

import Foundation

class InfoData: Identifiable {
    let id: Int
    let name: String
    var value: String
    /// Visual alert level for the value text (normal/yellow/red).
    var severity: InfoAlertSeverity

    init(id: Int, name: String, value: String = "", severity: InfoAlertSeverity = .normal) {
        self.id = id
        self.name = name
        self.value = value
        self.severity = severity
    }
}
