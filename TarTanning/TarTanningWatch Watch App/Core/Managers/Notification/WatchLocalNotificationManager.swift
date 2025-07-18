//
//  WatchNotificationManager.swift
//  TarTanningWatch Watch App
//
//  Created by J on 7/17/25.
//

import Foundation
import UserNotifications

final class WatchLocalNotificationManager {
    
    static let shared = WatchLocalNotificationManager()
    
    private init() { }
    
    func scheduleNotification(for type: NotificationContentType, at date: Date, repeats: Bool = false, useUniqueId: Bool = false) {
        let finalId = useUniqueId ? UUID().uuidString : type.id

        NotificationScheduler.schedule(
            platform: "watchOS",
            id: finalId,
            title: type.title,
            body: type.body,
            date: date,
            repeats: repeats,
            categoryIdentifier: type.categoryIdentifier
        )
    }
    
    func cancelNotification(id: String) {
        NotificationScheduler.cancel(id: id)
    }
    
    func cancelAllNotifications() {
        NotificationScheduler.cancelAll()
    }
}
