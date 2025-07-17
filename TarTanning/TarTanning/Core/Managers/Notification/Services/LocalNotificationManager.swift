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
    
    func scheduleNotification(id: String, title: String, body: String, date: Date, repeats: Bool = false) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: repeats)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 스케줄 실패: \(error.localizedDescription)")
            } else {
                print("알림 예약 완료 \(id) - \(date)")
            }
        }
    }
    
    func scheduleNotification(for type: NotificationContentType, at date: Date, repeats: Bool = false) {
        scheduleNotification(
            id: type.id,
            title: type.title,
            body: type.body,
            date: date,
            repeats: repeats
        )
    }
    
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        print("알림 취소됨 \(id)")
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("모든 알림 취소됨")
    }
}
