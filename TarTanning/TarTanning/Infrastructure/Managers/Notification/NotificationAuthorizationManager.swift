//
//  NotificationAuthorizationManager.swift
//  TarTanning
//
//  Created by J on 7/17/25.
//

import Foundation
import UserNotifications

@MainActor
protocol NotificationAuthorizationManagerDelegate: AnyObject {
    func notificationAuthorizationDidUpdate(_ status: NotificationAuthStatus)
    func notificationAuthorizationDidFail(_ error: Error)
}

@MainActor
final class NotificationAuthorizationManager {
    static let shared = NotificationAuthorizationManager()
    
    weak var delegate: NotificationAuthorizationManagerDelegate?
    
    private init() {}
    
    func requestAuthorization() {
        print("🔄 [NotificationAuthorizationManager] Requesting notification authorization")
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        center.requestAuthorization(options: options) { [weak self] granted, error in
            if let error = error {
                print("❌ [NotificationAuthorizationManager] Authorization request failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.delegate?.notificationAuthorizationDidFail(error)
                }
                return
            }
            print("✅ [NotificationAuthorizationManager] Authorization request completed, granted: \(granted)")
            self?.checkAuthorizationStatus()
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            let status: NotificationAuthStatus = {
                switch settings.authorizationStatus {
                case .authorized, .ephemeral:
                    return .authorized
                case .provisional:
                    return .provisional
                case .denied:
                    return .denied
                case .notDetermined:
                    return .notDetermined
                @unknown default:
                    return .notAvailable
                }
            }()
            
            // 상태별 로깅
            let statusMessage = switch status {
            case .authorized: "✅ [NotificationAuthorizationManager] Notification authorization granted"
            case .denied: "❌ [NotificationAuthorizationManager] Notification authorization denied"
            case .provisional: "📭 [NotificationAuthorizationManager] Notification authorization provisional"
            case .notDetermined: "📭 [NotificationAuthorizationManager] Notification authorization not determined"
            case .notAvailable: "❌ [NotificationAuthorizationManager] Notification authorization not available"
            }
            print(statusMessage)
            
            DispatchQueue.main.async {
                self?.delegate?.notificationAuthorizationDidUpdate(status)
            }
        }
    }
}
