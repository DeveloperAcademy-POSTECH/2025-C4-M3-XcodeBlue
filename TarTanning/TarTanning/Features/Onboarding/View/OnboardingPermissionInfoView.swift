//
//  OnboardingPermissionInfoView.swift
//  TarTanning
//
//  Created by J on 7/15/25.
//

import SwiftUI

struct OnboardingPermissionInfoView: View {
    
    let didTapContinueButton: () -> Void
    let requestAllPermissions: () async -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("필요한 권한")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 14)
            
            Text("탈태닝을 사용하고 일광시간을 체크하려면\n건강, 위치 및 알림 접근을 허용하십시오.")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.bottom, 72)
            
            VStack {
                InfoItem(
                    isSystemImage: false,
                    imageName: "healthAppIcon",
                    title: "건강 접근",
                    description: "건강앱을 사용하여 일광시간을 저장하십시오."
                )
                InfoItem(
                    imageName: "map.fill",
                    title: "위치 서비스 접근",
                    description: "이 앱은 현재 위치를 기반으로 자외선 지수와 피부 보호 팁을 제공하기 위해 위치 접근권한이 필요합니다."
                )
                InfoItem(
                    imageName: "bell.fill",
                    title: "알람 접근",
                    description: "피부 보호와 건강한 자외선 습관을 위해, 자외선 경고와 선크림 알림을 보내드릴게요."
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            OnboardingButton(title: "계속", style: .primary) {
                Task {
                    await requestAllPermissions()
                    didTapContinueButton()
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    OnboardingPermissionInfoView(
        didTapContinueButton: {}, requestAllPermissions: {}
    )
}
