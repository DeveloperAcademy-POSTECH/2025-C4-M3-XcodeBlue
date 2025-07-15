//
//  OnboardingStep.swift
//  TarTanning
//
//  Created by J on 7/15/25.
//

import Foundation

enum OnboardingStep: Hashable, Identifiable {
    // 전체 뷰
    case watchInfo
    case permissionInfo
    case skinTypeInfo
    
    // 시트 뷰
    case startSheet
    case healthkitPermissionSheet
    case skinTypeDetailSheet
    
    var id: String {
        String(describing: self)
    }
}
