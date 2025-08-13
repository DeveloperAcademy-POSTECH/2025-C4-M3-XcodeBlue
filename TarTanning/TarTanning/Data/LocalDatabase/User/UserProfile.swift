//
//  UserProfile.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation

struct UserProfile: Codable {
    var skinType: SkinType // 유저의 스킨 유형
    var spfLevel: SPFLevel // 유저의 SPF 레벨 (초기값: 30)
    
    init(skinType: SkinType = .type3, spfLevel: SPFLevel = .spf30) {
        self.skinType = skinType
        self.spfLevel = spfLevel
    }
}

extension UserProfile {
    static let mockUser = UserProfile(skinType: .type3, spfLevel: .spf30)
    
    /// 기본 사용자 프로필 (온보딩 완료 전)
    static let defaultUser = UserProfile(skinType: .type3, spfLevel: .spf30)
}
