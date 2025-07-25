//
//  OnboardingStartView.swift
//  TarTanning
//
//  Created by J on 7/15/25.
//

import SwiftUI

struct OnboardingStartView: View {
    var onClose: () -> Void
    
    var body: some View {
        VStack {
            
            Spacer()
            
            Text("탈태닝 시작하기")
                .font(.title)
                .fontWeight(.bold)
            
            Spacer()
            
            VStack {
                InfoItem(
                    imageName: "applewatch",
                    title: "일광 노출 누적",
                    description: "Apple Watch 에서 수집된 일광량을 모니터링합니다."
                )
                InfoItem(
                    imageName: "sun.max",
                    title: "실시간 자외선 알림",
                    description: "현재 위치와 날씨 데이터를 기반으로 최적의 선크림 사용 시점을 알려드립니다."
                )
                InfoItem(
                    imageName: "person.circle",
                    title: "개인 맞춤 추천",
                    description: "UV 지수, 날씨, 개인 활동 패턴을 분석해 당신만의 피부 관리 가이드를 제공합니다."
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
                .frame(height: 180)
            
            OnboardingButton(title: "계속", style: .primary, action: onClose)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    OnboardingStartView(
        onClose: {}
    )
}
