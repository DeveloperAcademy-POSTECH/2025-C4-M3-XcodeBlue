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
         repeats: Bool = false
     ) {
         guard date > Date() else {
             return
         }

         let content = UNMutableNotificationContent()
         content.title = title
         content.body = body
         content.sound = .default

         let triggerDate = Calendar.current.dateComponents(
             [.year, .month, .day, .hour, .minute, .second],
             from: date
         )
         
         let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: repeats)

         let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
         UNUserNotificationCenter.current().add(request) { error in
             if let error = error {
                 print("[\(platform)] 알림 등록 실패: \(error.localizedDescription)")
             } else {
                 print("[\(platform)] 알림 등록 성공 - \(id)")
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
