//
//  GetUserProfileUseCase.swift
//  TarTanning
//
//  Created by Jun on 7/26/25.
//

import Foundation

/**
 목적: 사용자 프로필 조회
 입력: 없음
 출력: UserProfile
 비즈니스 로직:
 - UserDefaults에서 사용자 프로필 로드
 - 기본값 반환 (프로필이 없는 경우)
 */

final class GetUserProfileUseCase {
    private let userDefaultManager = UserDefaultManager.shared
    
    init() {}
    
    // MARK: - Public Methods
    
    /// 사용자 프로필 조회
    func getUserProfile() -> UserProfile {
        print("📊 [GetUserProfileUseCase] Fetching user profile")
        
        let profile = userDefaultManager.loadUserProfile()
        
        print("✅ [GetUserProfileUseCase] User profile loaded: \(profile.skinType.title), SPF \(profile.spfLevel.rawValue)")
        return profile
    }
    
    /// 피부타입 조회
    func getSkinType() -> SkinType {
        let profile = getUserProfile()
        return profile.skinType
    }
    
    /// SPF 레벨 조회
    func getSPFLevel() -> SPFLevel {
        let profile = getUserProfile()
        return profile.spfLevel
    }
    
    /// 온보딩 완료 상태 조회
    func isOnboardingCompleted() -> Bool {
        return userDefaultManager.isOnboardingCompleted()
    }
    
    /// 첫 실행 여부 조회
    func isFirstLaunch() -> Bool {
        return userDefaultManager.isFirstLaunch()
    }
} 