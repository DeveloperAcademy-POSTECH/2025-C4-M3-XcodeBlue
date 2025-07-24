//
//  UserInfoRow.swift
//  TarTanning
//
//  Created by J on 7/22/25.
//

import SwiftUI

struct UserInfoRow: View {
    var title: String
    var description: String
    var displayType: String
    var action: () -> Void
    
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
            
            Button(action: action) {
                Text(displayType)
                    .font(.body)
                    .frame(minWidth: 84, alignment: .center)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack {
        UserInfoRow(title: "스킨타입 설정", description: "피츠패트릭 스킨타입을 수정합니다.", displayType: "IV", action: {})
        UserInfoRow(title: "선크림SPF 설정", description: "피츠패트릭 스킨타입을 수정합니다.", displayType: "SPF 50", action: {})
    }
}
