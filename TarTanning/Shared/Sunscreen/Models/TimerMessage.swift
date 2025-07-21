//
//  TimerMessage.swift
//  TarTanning (iOS + watchOS)
//
//  Created by taeni on 7/17/25.
//

import Foundation

struct TimerMessage: Codable {
    let endTime: Date
    let state: TimerState
}
