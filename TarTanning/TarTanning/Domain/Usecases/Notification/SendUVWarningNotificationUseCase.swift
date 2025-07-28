//
//  SendUVWarningNotificationUseCase.swift
//  TarTanning
//
//  Created by taeni on 7/25/25.
//

/**
 목적: UV 위험 상황 시 알림 발송
 입력: 현재 MED 진행률, 예상 위험 시간
 출력: 알림 발송 성공/실패
 비즈니스 로직:

 MED 70% 이상 시 경고 알림
 디바이스별 알림 방식 (iOS: 배너, Watch: 햅틱)
 */
import Foundation

struct SendUVWarningNotificationUseCase {
    let uvDose: Double
    let maxMED: Double
    
    func execute() {
        let percent = Int((uvDose / maxMED) * 100)
        guard percent >= 70 else {
            print("🟢 [SendUVWarningNotificationUseCase] 아직 MED 경고 기준 미달 (\(percent)%)")
            return
        }
        
        let notification = NotificationContentType.medWarning(percent: percent)
        LocalNotificationManager.shared.scheduleNotification(
            for: notification,
            at: Date().addingTimeInterval(3),
            useUniqueId: true
        )
        print("🚨 [SendUVWarningNotificationUseCase] MED \(percent)% 초과! 알림 발송 완료")
    }
}
