//
//  WatchTimerNotificationManager.swift
//  TarTanning Watch App
//
//  Created by taeni on 7/18/25.
//

import UserNotifications
import WatchKit

final class WatchTimerNotificationManager {
    static let shared = WatchTimerNotificationManager()
    
    private init() {}
    
    /// 알림 권한 요청
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            print("[Watch] Notification permission granted: \(granted)")
            return granted
        } catch {
            print("[Watch] Notification permission error: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 타이머 완료 알림 스케줄링
    func scheduleTimerCompletionNotification(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "타이머 완료"
        content.body = "설정한 시간이 완료되었습니다."
        content.sound = UNNotificationSound.default
        
        // watchOS 전용 카테고리 설정
        content.categoryIdentifier = "TIMER_COMPLETION"
        
        let timeInterval = date.timeIntervalSinceNow
        guard timeInterval > 0 else {
            print("[Watch] Invalid notification time interval: \(timeInterval)")
            return
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "watchTimerCompletion",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Watch] Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("[Watch] Timer completion notification scheduled for: \(date)")
            }
        }
    }
    
    /// 알림 취소
    func cancelTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["watchTimerCompletion"]
        )
        print("[Watch] Timer notification cancelled")
    }
    
    /// 즉시 알림 표시 (타이머 완료 시)
    func showImmediateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "타이머 완료!"
        content.body = "시간이 완료되었습니다."
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "TIMER_COMPLETION"
        
        // 즉시 알림을 위한 짧은 시간 간격
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 0.1,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "immediateTimerCompletion",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Watch] Failed to show immediate notification: \(error.localizedDescription)")
            } else {
                print("[Watch] Immediate notification shown")
            }
        }
    }
}
