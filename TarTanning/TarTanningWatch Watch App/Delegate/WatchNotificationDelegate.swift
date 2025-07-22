//
//  WatchNotificationDelegate.swift
//  TarTanning Watch App
//
//  Created by taeni on 7/18/25.
//

import UserNotifications
import WatchKit

final class WatchNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = WatchNotificationDelegate()
    
    private override init() {
        super.init()
    }
    
    /// 앱이 포그라운드에 있을 때 알림 표시 여부 결정
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("[Watch] Notification will present: \(notification.request.identifier)")
        
        // 앱이 활성 상태여도 알림 표시
        completionHandler([.banner, .sound])
    }
    
    /// 알림 탭 시 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        print("[Watch] Notification tapped: \(identifier)")
        
        if identifier.contains("timerCompletion") {
            // 타이머 완료 알림 탭 시 앱으로 이동
            // 필요시 특정 화면으로 네비게이션
        }
        
        completionHandler()
    }
}
