//
//  SkinType.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation
import SwiftUI

enum SkinType: Int, CaseIterable, Identifiable {
    case type1 = 1
    case type2
    case type3
    case type4
    case type5
    case type6
    
    var id: Int { rawValue }
    
    var title: String {
        "\(rawValue)형"
    }
    
    var summary: String {
        switch self {
        case .type1: "매우 하얀 피부, 주근깨 많음"
        case .type2: "하얀 피부, 주근깨 있음"
        case .type3: "약간 어두운 피부"
        case .type4: "올리브톤 또는 황갈색 피부"
        case .type5: "갈색 피부"
        case .type6: "매우 어두운 갈색/검은 피부"
        }
    }
    
    var description: String {
        switch self {
        case .type1: "항상 타거나 화상을 입음, 거의 태닝되지 않음"
        case .type2: "쉽게 타고, 태닝이 어려움"
        case .type3: "가끔 타지만 점진적으로 태닝됨"
        case .type4: "거의 타지 않고 쉽게 태닝됨"
        case .type5: "거의 타지 않고 매우 쉽게 태닝됨"
        case .type6: "거의 타지 않음, 자연스럽게 어두운 색소"
        }
    }
    
    var color: Color {
        switch self {
        case .type1: Color(red: 0.99, green: 0.93, blue: 0.87)
        case .type2: Color(red: 0.99, green: 0.89, blue: 0.81)
        case .type3: Color(red: 0.93, green: 0.74, blue: 0.6)
        case .type4: Color(red: 0.93, green: 0.64, blue: 0.47)
        case .type5: Color(red: 0.65, green: 0.37, blue: 0.16)
        case .type6: Color(red: 0.22, green: 0.13, blue: 0.11)
        }
    }
    
    /// 피부 타입의 하루 최대 권장 MED 평균값 (단위: J/m^2)
    var maxMED: Double {
        switch self {
        case .type1: 150.0
        case .type2: 300.0
        case .type3: 400.0
        case .type4: 500.0
        case .type5: 700.0
        case .type6: 1200.0
        }
    }
}
