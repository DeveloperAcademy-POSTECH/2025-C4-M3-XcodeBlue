//
//  TimerNotificationManager.swift
//  TarTanning
//
//  Created by taeni on 7/17/25.
//

import Foundation
import UserNotifications

enum TimerNotificationManager {
    static func sendWatchNotification() {
        let content = UNMutableNotificationContent()
        content.title = "타이머 완료"
        content.body = "설정한 시간이 끝났습니다."

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
