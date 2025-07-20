//
//  NotificationAuthTestView.swift
//  TarTanning
//
//  Created by J on 7/17/25.
//

import SwiftUI

struct NotificationAuthTestView: View {
    
    @StateObject private var viewModel = NotificationAuthTestViewModel()
    
    var body: some View {
        VStack {
            Text("NotificationAuthTestView")
            
            Text("현재 상황: \(viewModel.authStatus.description)")
                
            Button("권한 요청") {
                viewModel.requestAuth()
            }
            
            Button("상태 새로고침") {
                viewModel.fetchAuthStatus()
            }
            
            if let error = viewModel.errorMessage {
                Text("오류: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            VStack {
                Button("MED 알림 30% 예약") {
                    viewModel.scheduleMEDWarning(percent: 30)
                }
                
                Button("MED 알림 70% 예약") {
                    viewModel.scheduleMEDWarning(percent: 70)
                }
                
                Button("선크림 알림 (UV 7) 예약") {
                    viewModel.scheduleSunscreenReminder(uvIdex: 7)
                }
                
                Button("선크림 알림 (인터렉티브)") {
                    viewModel.scheduleSunscreenPrompt()
                }

                Button("모든 알림 취소") {
                    viewModel.cancelAll()
                }
                
                if let userResponse = viewModel.userResponse {
                    Text("사용자 응답: \(userResponse == "yes" ? "예" : "아니오")")
                        .padding()
                        .foregroundColor(.blue)
                }
            }
        }
        
    }
}
