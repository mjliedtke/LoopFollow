// LoopFollow
// BAge.swift

import Foundation

extension MainViewController {
    // NS Bage Web Call
    func webLoadNSBage() {
        let lastDateString = dateTimeUtils.getDateTimeString(addingDays: -60)
        let currentTimeString = dateTimeUtils.getDateTimeString()

        let parameters: [String: String] = [
            "find[eventType]": NightscoutUtils.EventType.bage.rawValue,
            "find[created_at][$gte]": lastDateString,
            "find[created_at][$lte]": currentTimeString,
            "count": "1",
        ]

        NightscoutUtils.executeRequest(eventType: .bage, parameters: parameters) { (result: Result<[bageData], Error>) in
            switch result {
            case let .success(data):
                DispatchQueue.main.async {
                    self.updateBage(data: data)
                }
            case let .failure(error):
                LogManager.shared.log(category: .nightscout, message: "webLoadNSBage, failed to fetch data: \(error.localizedDescription)")
            }
        }
    }

    // NS Bage Response Processor
    func updateBage(data: [bageData]) {
        infoManager.clearInfoData(type: .bage)

        if data.count == 0 {
            return
        }
        currentBage = data[0]
        let lastBageString = data[0].created_at

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate,
                                   .withTime,
                                   .withDashSeparatorInDate,
                                   .withColonSeparatorInTime]

        if let bageTime = formatter.date(from: (lastBageString as! String))?.timeIntervalSince1970 {
            let now = dateTimeUtils.getNowTimeIntervalUTC()
            let secondsAgo = now - bageTime

            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .positional
            formatter.allowedUnits = [.day, .hour]
            formatter.zeroFormattingBehavior = [.pad]

            if let formattedDuration = formatter.string(from: secondsAgo) {
                infoManager.updateInfoData(type: .bage, value: formattedDuration)
            }
        }
    }
}
