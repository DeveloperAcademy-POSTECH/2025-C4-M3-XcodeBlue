//
//  NotificationScheduler.swift
//  TarTanning
//
//  Created by J on 7/17/25.
//

import Foundation
import UserNotifications

enum NotificationScheduler {
    
    static func schedule(
        platform: String,
        id: String,
        title: String,
        body: String,
        date: Date,
        repeats: Bool = false,
        categoryIdentifier: String? = nil,
        useUniqueIdentifier: Bool = false
    ) {
        guard date > Date() else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        if let category = categoryIdentifier {
            content.categoryIdentifier = category
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(date.timeIntervalSinceNow, 1), repeats: repeats)
        
        let finalId = useUniqueIdentifier ? UUID().uuidString : id
        
        let request = UNNotificationRequest(identifier: finalId, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[\(platform)] 알림 등록 실패: \(error.localizedDescription)")
            } else {
                print("[\(platform)] 알림 등록 성공 - \(finalId)")
            }
        }
    }
    
    static func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
