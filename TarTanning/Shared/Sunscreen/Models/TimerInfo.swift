//
//  TimerInfo.swift
//  TarTanning (iOS + watchOS)
//
//  Created by taeni on 7/17/25.
//

import Foundation

struct TimerInfo: Codable {
    let startDate: Date
    let duration: TimeInterval
    
    var endDate: Date {
        return startDate.addingTimeInterval(duration)
    }
    
    var remainingTime: TimeInterval {
        return max(endDate.timeIntervalSinceNow, 0)
    }
    
    var isActive: Bool {
        return remainingTime > 0
    }
}
