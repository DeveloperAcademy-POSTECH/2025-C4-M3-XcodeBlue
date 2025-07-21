//
//  AppDelegate.swift
//  TarTanning
//
//  Created by J on 7/17/25.
//

import Foundation
import UserNotifications
import WatchKit

class WatchAppDelegate: NSObject, WKExtensionDelegate, UNUserNotificationCenterDelegate {
    
    func applicationDidFinishLaunching() {
        UNUserNotificationCenter.current().delegate = self
        registerNotificationCategories()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    private func registerNotificationCategories() {
        let yesAction = UNNotificationAction(identifier: "SUNSCREEN_YES", title: "예", options: [])
        let noAction = UNNotificationAction(identifier: "SUNSCREEN_NO", title: "아니오", options: [])
        
        let category = UNNotificationCategory(
            identifier: "SUNSCREEN_CATEGORY",
            actions: [yesAction, noAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
