//
//  TimerSession.swift
//  TarTanning
//
//  Created by taeni on 7/17/25.
//

import Foundation

public struct TimerSession: Identifiable, Codable, Equatable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public let duration: TimeInterval

    public init(startDate: Date, endDate: Date, duration: TimeInterval) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
    }

    public var remainingTime: TimeInterval {
        max(0, endDate.timeIntervalSinceNow)
    }

    public var isCompleted: Bool {
        remainingTime <= 0
    }

    public var dictionary: [String: Any] {
        [
            "id": id.uuidString,
            "startDate": startDate.timeIntervalSince1970,
            "endDate": endDate.timeIntervalSince1970,
            "duration": duration
        ]
    }

    public static func from(dictionary: [String: Any]) -> TimerSession? {
        guard
            let start = dictionary["startDate"] as? TimeInterval,
            let end = dictionary["endDate"] as? TimeInterval,
            let duration = dictionary["duration"] as? TimeInterval
        else { return nil }

        return TimerSession(
            startDate: Date(timeIntervalSince1970: start),
            endDate: Date(timeIntervalSince1970: end),
            duration: duration
        )
    }
}

