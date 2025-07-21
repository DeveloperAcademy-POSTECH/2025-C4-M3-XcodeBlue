//
//  UserProfile.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation

struct UserProfile: Codable {
    var skinType: SkinType // 유저의 스킨 유형: .type3
}

extension UserProfile {
    static let mockUser = UserProfile(skinType: .type3)
}
