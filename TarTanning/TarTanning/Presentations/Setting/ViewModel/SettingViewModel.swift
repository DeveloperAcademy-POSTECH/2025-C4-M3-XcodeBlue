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
    // MARK: - 사용자 설정
    @AppStorage("selectedSkinType") private var selectedSkinTypeRaw: Int = 3
    @AppStorage("selectedSPF") var selectedSPF: Int = 30
    
    // MARK: - Picker Sheet 표시 여부
    @Published var isSkinTypePickerPresented: Bool = false
    @Published var isSPFPickerPresented: Bool = false
    
    var selectedSkinType: SkinType {
        get { SkinType(rawValue: selectedSkinTypeRaw) ?? .type3 }
        set { selectedSkinTypeRaw = newValue.rawValue }
    }

    var selectedSPFLevel: SPFLevel {
        get { SPFLevel(rawValue: selectedSPF) ?? .spf30 }
        set { selectedSPF = newValue.rawValue }
    }
    
    // MARK: - 디스플레이용 문자열
    var skinTypeDisplay: String {
        "\(selectedSkinType.romanNumeral)"
    }

    var spfDisplay: String {
        "\(selectedSPFLevel.displayTitle)"
    }

    func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
