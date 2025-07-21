//
//  TarTanningWatchApp.swift
//  TarTanningWatch Watch App
//
//  Created by J on 7/11/25.
//

import SwiftUI
import UserNotifications
import WatchKit

@main
struct TarTanningWatchWatchApp: App {
    // MARK: - Notification 병합 필요
    @WKExtensionDelegateAdaptor(WatchAppDelegate.self) var delegate
    
    init() {
        // 알림 델리게이트 설정
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // 알림 카테고리 등록
        setupNotificationCategories()
    }
    
    var body: some Scene {
        WindowGroup {
            WatchRootView()
        }
    }
    
    private func setupNotificationCategories() {
        let timerCategory = UNNotificationCategory(
            identifier: "TIMER_COMPLETION",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([timerCategory])
    }
}
