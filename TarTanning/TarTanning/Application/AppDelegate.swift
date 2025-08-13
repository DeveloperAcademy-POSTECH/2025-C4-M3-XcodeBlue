import Foundation
import UIKit
import SwiftData
import UserNotifications
import HealthKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    private var container: ModelContainer?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        registerNotificationCategories()
    
        // HKObserverQuery 설정 (권한 확인 포함)
        setupHealthKitObserverWhenReady()
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([])
    }
    
    private func registerNotificationCategories() {
        let yesAction = UNNotificationAction(identifier: "SUNSCREEN_YES", title: "예", options: [.foreground])
        let noAction = UNNotificationAction(identifier: "SUNSCREEN_NO", title: "아니오", options: [.foreground])
        
        let category = UNNotificationCategory(
            identifier: "SUNSCREEN_CATEGORY",
            actions: [yesAction, noAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "SUNSCREEN_YES":
            NotificationCenter.default.post(name: .sunscreenResponse, object: "yes")
        case "SUNSCREEN_NO":
            NotificationCenter.default.post(name: .sunscreenResponse, object: "no")
        default:
            break
        }
        
        completionHandler()
    }
    
    private func setupHealthKitObserverWhenReady() {
        // 즉시 시도 (이미 권한이 있는 경우)
        Task { @MainActor in
            HealthKitQueryFetchManager.shared.startObservingWhenAuthorized()
        }
        
        // 권한 변경 감지를 위한 NotificationCenter 관찰
        NotificationCenter.default.addObserver(
            forName: .healthKitAuthorizationChanged,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                HealthKitQueryFetchManager.shared.startObservingWhenAuthorized()
                print("🔄 [AppDelegate] HealthKit authorization changed - restarting Observer")
            }
        }
    }
}

extension Notification.Name {
    static let sunscreenResponse = Notification.Name("sunscreenResponse")
    static let healthKitAuthorizationChanged = Notification.Name("healthKitAuthorizationChanged") //
}
