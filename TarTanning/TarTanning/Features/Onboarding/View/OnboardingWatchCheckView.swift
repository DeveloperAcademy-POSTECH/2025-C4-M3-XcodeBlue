//
//  OnboardingWatchCheckView.swift
//  TarTanning
//
//  Created by J on 7/15/25.
//

import SwiftUI

struct OnboardingWatchCheckView: View {
    
    @State var isPresentedAlert = false
    
    var onNext: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            
            Spacer()
            
            Text("Apple Watch 보유 여부")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Apple Watch를 이용하면 일광 데이터를\n얻을 수 있습니다.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.gray)
                
                Text("애플 워치 7세대 또는 SE2세대 이상")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(.appleWatchMockup)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            VStack(spacing: 12) {
                OnboardingButton(
                    title: "네, 있습니다",
                    style: .primary,
                    action: onNext
                )
                
                OnboardingButton(
                    title: "아니요, 없습니다",
                    style: .secondary,
                    action: {
                        isPresentedAlert = true
                    }
                )
            }
            .padding(.horizontal, 20)
        }
        .alert(isPresented: $isPresentedAlert) {
            Alert(
                title: Text("Apple Watch"),
                message: Text("정확한 데이터를 위해선 Apple Watch가 필요합니다."),
                dismissButton: .default(Text("확인"))
            )
        }
    }
}

#Preview {
    OnboardingWatchCheckView(onNext: {})
}
