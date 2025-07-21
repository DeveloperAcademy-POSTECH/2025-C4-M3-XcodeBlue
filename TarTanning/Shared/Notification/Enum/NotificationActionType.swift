//
//  NotificationActionType.swift
//  TarTanning (iOS + watchOS)
//
//  Created by J on 7/18/25.
//

import Foundation
import UserNotifications

enum NotificationActionType: String {
    case sunscreenOn = "SUNSCREEN_ON"
    case sunscreenOff = "SUNSCREEN_OFF"
    
    var title: String {
        switch self {
        case .sunscreenOn: "On"
        case .sunscreenOff: "Off"
        }
    }
    
    var action: UNNotificationAction {
        UNNotificationAction(identifier: self.rawValue, title: self.title, options: [])
    }
}
