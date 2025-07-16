//
//  SkinTypeItem.swift
//  TarTanning
//
//  Created by J on 7/14/25.
//

import SwiftUI

struct SkinTypeItem: View {
    let skinType: SkinType
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            
            RoundedRectangle(cornerRadius: 8)
                .fill(skinType.color)
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(skinType.title)
                    .font(.system(size: 17))
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                
                Text(skinType.summary)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text(skinType.description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .inset(by: 0.5)
                .stroke(isSelected ? Color(red: 0, green: 0.53, blue: 1) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    VStack {
        SkinTypeItem(
            skinType: SkinType.type1, isSelected: true
        )
        SkinTypeItem(
            skinType: SkinType.type2, isSelected: false
        )
        SkinTypeItem(
            skinType: SkinType.type3, isSelected: false
        )
        SkinTypeItem(
            skinType: SkinType.type4, isSelected: false
        )
        SkinTypeItem(
            skinType: SkinType.type5, isSelected: false
        )
        SkinTypeItem(
            skinType: SkinType.type6, isSelected: false
        )
    }
    .padding(.horizontal, 20)
}
