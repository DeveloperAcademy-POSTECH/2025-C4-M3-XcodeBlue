//
//  NotificationCategoryType.swift
//  TarTanning (iOS + watchOS)
//
//  Created by J on 7/17/25.
//

import Foundation
import UserNotifications

enum NotificationCategoryType: String {
    case sunscreenPrompt = "SUNSCREEN_CATEGORY"
    
    var identifier: String {
        return self.rawValue
    }
    
    var actions: [UNNotificationAction] {
        switch self {
        case .sunscreenPrompt:
            return [
                NotificationActionType.sunscreenOn.action,
                NotificationActionType.sunscreenOff.action
            ]
        }
    }
    
    var category: UNNotificationCategory {
        return UNNotificationCategory(identifier: identifier, actions: actions, intentIdentifiers: [], options: [])
    }
}
