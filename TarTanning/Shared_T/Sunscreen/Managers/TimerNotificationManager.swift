//
//  TimerNotificationManager.swift.swift
//  TarTanning
//
//  Created by taeni on 7/17/25.
//

import UserNotifications

final class TimerNotificationManager {
    static let shared = TimerNotificationManager()
    
    func scheduleNotification(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "시간이 완료되었습니다!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: date.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: "timerDone", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timerDone"])
    }
    
    func scheduleTimerCompletionNotification(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "타이머 완료"
        content.body = "설정한 시간이 완료되었습니다."
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "TIMER_COMPLETION"
        
        let timeInterval = date.timeIntervalSinceNow
        guard timeInterval > 0 else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "iPhoneTimerCompletion",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[iPhone] Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("[iPhone] Timer completion notification scheduled")
            }
        }
    }
}
