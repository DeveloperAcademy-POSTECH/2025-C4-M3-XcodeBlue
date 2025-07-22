//
//  WatchNotificationTestViewModel.swift
//  TarTanningWatch Watch App
//
//  Created by J on 7/17/25.
//

import Foundation
import UserNotifications

@MainActor
final class WatchNotificationTestViewModel: ObservableObject {
    @Published var scheduledMessage: String?

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            print("워치 알림 권한: \(granted), 오류: \(String(describing: error))")
        }
    }

    func scheduleSunscreenPromptNotification() {
        let fireDate = Date().addingTimeInterval(2)
        LocalNotificationManager.shared.scheduleNotification(
            for: .sunscreenPrompt,
            at: fireDate,
            useUniqueId: true
        )
    }
    
    func scheduleMedWarningNotification() {
        let fireDate = Date().addingTimeInterval(2)
        LocalNotificationManager.shared.scheduleNotification(
            for: .medWarning(percent: 80),
            at: fireDate
        )
    }

    func cancelAllNotifications() {
        LocalNotificationManager.shared.cancelAllNotifications()
        scheduledMessage = "모든 알림 취소됨"
    }
    
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "선크림 타이머 끝!"
        content.body = "2시간마다 덧발라야 합니다. 덧바르셨나요?"
        content.sound = .default
        content.categoryIdentifier = "SUNSCREEN_CATEGORY"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 등록 실패: \(error.localizedDescription)")
            } else {
                print("알림 등록 성공 - \(content.categoryIdentifier)")
            }
        }
    }
}
