//
//  OnboardingViewModel.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation
import SwiftUI

final class OnboardingViewModel: ObservableObject {
    @AppStorage("selectedSkinType") private var selectedSkinTypeRaw: Int = 3
    
    @Published var currentStep: OnboardingStep = .watchInfo
    @Published var activeSheet: OnboardingStep? = .startSheet
    
    func nextMainView() {
        switch currentStep {
        case .watchInfo:
            currentStep = .permissionInfo
        case .permissionInfo:
            currentStep = .skinTypeInfo
        case .skinTypeInfo:
            break
        default:
            break
        }
    }
    
    var selectedSkinType: SkinType? {
        get { SkinType(rawValue: selectedSkinTypeRaw) }
        set { selectedSkinTypeRaw = newValue?.rawValue ?? 3 }
    }

    func selectSkinType(_ type: SkinType) {
        selectedSkinType = type
    }
}
