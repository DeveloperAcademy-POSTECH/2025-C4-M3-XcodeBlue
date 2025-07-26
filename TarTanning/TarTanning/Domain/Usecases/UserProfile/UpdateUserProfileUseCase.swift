//
//  UpdateUserProfileUseCase.swift
//  TarTanning
//
//  Created by Jun on 7/26/25.
//

import Foundation

/**
 목적: 사용자 프로필 업데이트
 입력: 업데이트할 프로필 정보
 출력: 업데이트 결과
 비즈니스 로직:
 - UserDefaults에 사용자 프로필 저장
 - 프로필 변경 이벤트 처리
 */

final class UpdateUserProfileUseCase {
    private let userDefaultManager = UserDefaultManager.shared
    
    init() {}
    
    // MARK: - Public Methods
    
    /// 전체 사용자 프로필 업데이트
    func updateUserProfile(_ profile: UserProfile) {
        print("🔄 [UpdateUserProfileUseCase] Updating user profile")
        
        userDefaultManager.saveUserProfile(profile)
        
        print("✅ [UpdateUserProfileUseCase] User profile updated: \(profile.skinType.title), SPF \(profile.spfLevel.rawValue)")
    }
    
    /// 피부타입 업데이트
    func updateSkinType(_ skinType: SkinType) {
        print("🔄 [UpdateUserProfileUseCase] Updating skin type to: \(skinType.title)")
        
        userDefaultManager.updateSkinType(skinType)
        
        print("✅ [UpdateUserProfileUseCase] Skin type updated successfully")
    }
    
    /// SPF 레벨 업데이트
    func updateSPFLevel(_ spfLevel: SPFLevel) {
        print("🔄 [UpdateUserProfileUseCase] Updating SPF level to: \(spfLevel.displayTitle)")
        
        userDefaultManager.updateSPFLevel(spfLevel)
        
        print("✅ [UpdateUserProfileUseCase] SPF level updated successfully")
    }
    
    /// 온보딩 완료 상태 설정
    func setOnboardingCompleted(_ completed: Bool) {
        print("🔄 [UpdateUserProfileUseCase] Setting onboarding completed: \(completed)")
        
        userDefaultManager.setOnboardingCompleted(completed)
        
        print("✅ [UpdateUserProfileUseCase] Onboarding status updated")
    }
    
    /// 사용자 프로필 초기화
    func resetUserProfile() {
        print("🔄 [UpdateUserProfileUseCase] Resetting user profile")
        
        userDefaultManager.clearUserProfile()
        
        print("✅ [UpdateUserProfileUseCase] User profile reset to default")
    }
    
    /// 모든 데이터 초기화
    func resetAllData() {
        print("🔄 [UpdateUserProfileUseCase] Resetting all data")
        
        userDefaultManager.resetAllData()
        
        print("✅ [UpdateUserProfileUseCase] All data reset")
    }
} 