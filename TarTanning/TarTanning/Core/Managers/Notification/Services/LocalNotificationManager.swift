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
    
    func scheduleNotification(for type: NotificationContentType, at date: Date, repeats: Bool = false, useUniqueId: Bool = false) {
        
        let finalId = useUniqueId ? UUID().uuidString : type.id
        
        NotificationScheduler.schedule(
            platform: "iOS",
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
