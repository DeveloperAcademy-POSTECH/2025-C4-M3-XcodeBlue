//
//  NotificationCategoryType.swift
//  TarTanning
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
                UNNotificationAction(identifier: "SUNSCREEN_YES", title: "Yes", options: []),
                UNNotificationAction(identifier: "SUNSCREEN_NO", title: "No", options: [])
            ]
        }
    }
    
    var category: UNNotificationCategory {
        return UNNotificationCategory(identifier: identifier, actions: actions, intentIdentifiers: [], options: [])
    }
}
