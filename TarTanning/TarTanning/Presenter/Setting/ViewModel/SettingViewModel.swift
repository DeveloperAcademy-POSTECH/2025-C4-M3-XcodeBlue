//
//  SettingViewModel.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Dependencies
    private let userDefaultManager = UserDefaultManager.shared
    
    // MARK: - Published Properties
    @Published var currentUserProfile: UserProfile
    
    // MARK: - Picker Sheet 표시 여부
    @Published var isSkinTypePickerPresented: Bool = false
    @Published var isSPFPickerPresented: Bool = false
    
    // MARK: - Initialization
    init() {
        // UserDefaultManager에서 현재 사용자 프로필 로드
        self.currentUserProfile = userDefaultManager.loadUserProfile()
    }
    
    // MARK: - Computed Properties
    var selectedSkinType: SkinType {
        get { currentUserProfile.skinType }
        set { 
            currentUserProfile.skinType = newValue
            userDefaultManager.updateSkinType(newValue)
        }
    }

    var selectedSPFLevel: SPFLevel {
        get { currentUserProfile.spfLevel }
        set { 
            currentUserProfile.spfLevel = newValue
            userDefaultManager.updateSPFLevel(newValue)
        }
    }
    
    // MARK: - 디스플레이용 문자열
    var skinTypeDisplay: String {
        "\(selectedSkinType.romanNumeral)형"
    }

    var spfDisplay: String {
        "\(selectedSPFLevel.displayTitle)"
    }

    // MARK: - Actions
    func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    /// 사용자 프로필 새로고침 (다른 화면에서 변경된 경우)
    func refreshUserProfile() {
        currentUserProfile = userDefaultManager.loadUserProfile()
    }
}
