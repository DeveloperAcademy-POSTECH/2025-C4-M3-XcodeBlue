//
//  WatchNotificationTestView.swift
//  TarTanningWatch Watch App
//
//  Created by J on 7/17/25.
//

import SwiftUI

struct WatchNotificationTestView: View {
    @StateObject private var viewModel = WatchNotificationTestViewModel()
    
    var body: some View {
        VStack(spacing: 4) {
            Button("🌞 선크림 알림 테스트") {
                viewModel.scheduleSunscreenPromptNotification()
            }

            Button("⚠️ 자외선 경고 알림") {
                viewModel.scheduleMedWarningNotification()
            }

            Button("❌ 모든 알림 취소") {
                viewModel.cancelAllNotifications()
            }
            
            Text(viewModel.scheduledMessage ?? "")
        }
        .padding()
    }
}

#Preview {
    WatchNotificationTestView()
}
