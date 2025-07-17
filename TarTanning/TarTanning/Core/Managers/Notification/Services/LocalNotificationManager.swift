//
//  LocalNotificationManager.swift
//  TarTanning
//
//  Created by J on 7/17/25.
//

import Foundation
import UserNotifications

final class LocalNotificationManager {
    
    static let shared = LocalNotificationManager()
    
    private init() { }
    
    func scheduleNotification(for type: NotificationContentType, at date: Date, repeats: Bool = false) {
        NotificationScheduler.schedule(
            platform: "iOS",
            id: type.id,
            title: type.title,
            body: type.body,
            date: date,
            repeats: repeats
        )
    }
    
    func cancelNotification(id: String) {
        NotificationScheduler.cancel(id: id)
    }
    
    func cancelAllNotifications() {
        NotificationScheduler.cancelAll()
    }
}
