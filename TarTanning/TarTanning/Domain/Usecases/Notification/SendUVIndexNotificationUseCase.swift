//
//  SendUVIndexNotificationUseCase.swift
//  TarTanning
//
//  Created by J on 7/28/25.
//

import Foundation

struct SendUVIndexNotificationUseCase {
    let uvIndex: Double
    
    func execute() {
        let intUV = Int(uvIndex)
        
        // 3 이상일 때 알림 (필요시 조건 조정)
        guard intUV >= 3 else {
            print("🟢 [SendUVIndexNotificationUseCase] UV Index \(intUV) - 알림 조건 미달")
            return
        }
        
        let notification = NotificationContentType.sunscreenReminder(uvIndex: intUV)
        LocalNotificationManager.shared.scheduleNotification(
            for: notification,
            at: Date().addingTimeInterval(3),
            useUniqueId: true
        )
        
        print("☀️ [SendUVIndexNotificationUseCase] UV Index \(intUV) 알림 발송 완료")
    }
}
