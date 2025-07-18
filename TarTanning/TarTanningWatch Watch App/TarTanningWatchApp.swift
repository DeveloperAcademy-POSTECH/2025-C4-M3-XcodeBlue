//
//  TarTanningWatchApp.swift
//  TarTanningWatch Watch App
//
//  Created by J on 7/11/25.
//

import SwiftUI
import UserNotifications

@main
struct TarTanningWatchWatchApp: App {
    
    init() {
        // 알림 델리게이트 설정
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // 알림 카테고리 등록
        setupNotificationCategories()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
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
