//
//  OnboardingButton.swift
//  TarTanning
//
//  Created by J on 7/14/25.
//

import SwiftUI

struct OnboardingButton: View {
    
    var title: String = "계속"
    var style: ButtonStyleType = .primary
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(style.textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 10)
                .background(style.backgroundColor)
                .cornerRadius(8)
        }
    }
}

#Preview {
    OnboardingButton()
    OnboardingButton(
        style: ButtonStyleType.secondary
    )
}
