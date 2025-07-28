import Foundation
import UIKit
import SwiftData
import UserNotifications
import HealthKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var syncUVDataInBackgroundUseCase: SyncUVDataInBackgroundUseCase?
    private var container: ModelContainer?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        registerNotificationCategories()

        do {
            container = try ModelContainer(for: LocationWeather.self, DailyUVExpose.self, UVExposeRecord.self, HourlyWeather.self)
            if let context = container?.mainContext {
                let useCase = SyncUVDataInBackgroundUseCase(context: context)
                syncUVDataInBackgroundUseCase = useCase

                if let type = HKObjectType.quantityType(forIdentifier: .timeInDaylight) {
                    Task {
                        await HealthKitBackgroundManager.shared.configure(syncUseCase: useCase, for: type)
                    }
                }
            }
        } catch {
            print("❌ [AppDelegate] Failed to create SwiftData container: \(error)")
        }

        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
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
}

extension Notification.Name {
    static let sunscreenResponse = Notification.Name("sunscreenResponse")
}
