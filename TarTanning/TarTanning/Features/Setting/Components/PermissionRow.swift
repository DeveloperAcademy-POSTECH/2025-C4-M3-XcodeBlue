//
//  PermissionRow.swift
//  TarTanning
//
//  Created by J on 7/22/25.
//

import SwiftUI

struct PermissionRow: View {
    var title: String
    var description: String
    var openSettings: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.title3)
                
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: openSettings) {
                Text("설정하기")
                    .font(.body)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack {
        PermissionRow(title: "알림 설정", description: "자외선과 관련된 알림을 알려드립니다.", openSettings: {})
        PermissionRow(title: "위치 설정", description: "현재 지역의 자외선 정보를 위한 위치정보를 수집합니다.", openSettings: {})
    }
    
}
