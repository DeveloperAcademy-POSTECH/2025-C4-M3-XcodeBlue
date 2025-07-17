//
//  NotificationTestView.swift
//  TarTanningWatch Watch App
//
//  Created by J on 7/17/25.
//

import SwiftUI

struct NotificationTestView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("🔔 워치 알림 테스트")
                .font(.headline)

            Button("5초 후 알림") {
                let fireDate = Date().addingTimeInterval(5)
                WatchLocalNotificationManager.shared.scheduleNotification(
                    for: .medWarning(percent: 8),
                    at: fireDate
                )
            }

            Button("모든 알림 취소") {
                WatchLocalNotificationManager.shared.cancelAllNotifications()
            }
        }
        .padding()
    }
}

#Preview {
    NotificationTestView()
}
