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
    weak var delegate: NotificationAuthorizationManagerDelegate?
    
    init(delegate: NotificationAuthorizationManagerDelegate? = nil) {
        self.delegate = delegate
    }
    
    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        center.requestAuthorization(options: options) { [weak self] granted, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.delegate?.notificationAuthorizationDidFail(error)
                }
                return
            }
            self?.fetchAuthorizationStatus()
        }
    }
    
    func fetchAuthorizationStatus() {
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
            
            DispatchQueue.main.async {
                self?.delegate?.notificationAuthorizationDidUpdate(status)
            }
        }
    }
}


