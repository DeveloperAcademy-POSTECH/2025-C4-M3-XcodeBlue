//
//  NotificationAuthTestViewModel.swift
//  TarTanning
//
//  Created by J on 7/17/25.
//

import Foundation

@MainActor
final class NotificationAuthTestViewModel: ObservableObject {
    @Published var authStatus: NotificationAuthStatus = .notDetermined
    @Published var errorMessage: String?
    @Published var scheduledMessage: String?
    
    private lazy var authManager = NotificationAuthorizationManager(delegate: self)
    
    func requestAuth() {
        authManager.requestAuthorization()
    }
    
    func fetchAuthStatus() {
        authManager.fetchAuthorizationStatus()
    }
    
    func scheduleMEDWarning(percent: Int) {
        let type = NotificationContentType.medWarning(percent: percent)
        let date = Date().addingTimeInterval(5) // 5초 뒤
        
        LocalNotificationManager.shared.scheduleNotification(for: type, at: date)
        scheduledMessage = "예약 완료 \(type.title)"
    }
    
    func scheduleSunscreenReminder(uvIdex: Int) {
        let type = NotificationContentType.sunscreenReminder(uvIndex: uvIdex)
        let date = Date().addingTimeInterval(5)
        
        LocalNotificationManager.shared.scheduleNotification(for: type, at: date)
        scheduledMessage = "예약 완료 \(type.title)"
    }
    
    func cancelAll() {
        LocalNotificationManager.shared.cancelAllNotifications()
        scheduledMessage = "모든 알림 취소됨"
    }
}

extension NotificationAuthTestViewModel: NotificationAuthorizationManagerDelegate {
    func notificationAuthorizationDidUpdate(_ status: NotificationAuthStatus) {
        authStatus = status
    }
    
    func notificationAuthorizationDidFail(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}
