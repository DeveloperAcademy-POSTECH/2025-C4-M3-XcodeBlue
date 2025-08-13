//
//  InfoItem.swift
//  TarTanning
//
//  Created by J on 7/14/25.
//

import SwiftUI

struct InfoItem: View {
    var isSystemImage: Bool = true
    var imageName: String
    var title: String
    var description: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            if isSystemImage {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
            } else {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.body)
                    .fontWeight(.bold)
                
                Text(description)
                    .font(.callout)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    VStack(alignment: .leading) {
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
    .padding(.horizontal, 16)

    VStack(alignment: .leading) {
        
        InfoItem(
            isSystemImage: false,
            imageName: "healthAppIcon",
            title: "건강 접근",
            description: "건강앱을 사용하여 일광시간을 저장하십시오."
        )
        InfoItem(
            imageName: "person.circle",
            title: "위치 서비스 접근",
            description: "이 앱은 현재 위치를 기반으로 자외선 지수와 피부 보호 팁을 제공하기 위해 위치 접근권한이 필요합니다."
        )
        InfoItem(
            imageName: "person.circle",
            title: "알람 접근",
            description: "피부 보호와 건강한 자외선 습관을 위해, 자외선 정보와 선크림 알림을 보내드릴게요."
        )
    }
    .padding(.horizontal, 20)
    
}
