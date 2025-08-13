//
//  OnboardingSkinTypeView.swift
//  TarTanning
//
//  Created by J on 7/15/25.
//

import SwiftUI

struct OnboardingSkinTypeView: View {
    
    let selectedType: SkinType?
    let onTapSkinTypeInfo: () -> Void
    let onNext: () -> Void
    let onSelect: (SkinType) -> Void
    
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 8) {
                Spacer()
                
                HStack {
                    Text("피부 타입 선택")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Button {
                        onTapSkinTypeInfo()
                    } label: {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 17)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(SkinType.allCases) { type in
                            SkinTypeItem(skinType: type, isSelected: selectedType == type)
                                .onTapGesture {
                                    onSelect(type)
                                }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                
                OnboardingButton(
                    title: "계속",
                    style: .primary,
                    action: onNext
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

struct PreviewWrapper: View {
    @State private var selected: SkinType? = SkinType.type3

    var body: some View {
        OnboardingSkinTypeView(
            selectedType: selected,
            onTapSkinTypeInfo: {},
            onNext: {},
            onSelect: { type in
                selected = type
            }
        )
    }
}

#Preview {
    PreviewWrapper()
}
