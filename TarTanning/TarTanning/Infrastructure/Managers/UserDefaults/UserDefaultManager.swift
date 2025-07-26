//
//  UserDefaultManager.swift
//  TarTanning
//
//  Created by Jun on 7/26/25.
//

import Foundation

final class UserDefaultManager {
    static let shared = UserDefaultManager()
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Keys
    private enum Keys {
        static let userProfile = "userProfile"
        static let isOnboardingCompleted = "isOnboardingCompleted"
        static let isFirstLaunch = "isFirstLaunch"
    }
    
    // MARK: - User Profile Management
    
    /// 사용자 프로필 저장
    func saveUserProfile(_ profile: UserProfile) {
        do {
            let data = try JSONEncoder().encode(profile)
            userDefaults.set(data, forKey: Keys.userProfile)
            print("✅ [UserDefaultManager] User profile saved: \(profile.skinType.title), SPF \(profile.spfLevel.rawValue)")
        } catch {
            print("❌ [UserDefaultManager] Failed to save user profile: \(error)")
        }
    }
    
    /// 사용자 프로필 로드
    func loadUserProfile() -> UserProfile {
        guard let data = userDefaults.data(forKey: Keys.userProfile) else {
            print("📭 [UserDefaultManager] No saved user profile found, using default")
            return UserProfile.defaultUser
        }
        
        do {
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            print("✅ [UserDefaultManager] User profile loaded: \(profile.skinType.title), SPF \(profile.spfLevel.rawValue)")
            return profile
        } catch {
            print("❌ [UserDefaultManager] Failed to load user profile: \(error), using default")
            return UserProfile.defaultUser
        }
    }
    
    /// 피부타입 업데이트
    func updateSkinType(_ skinType: SkinType) {
        var profile = loadUserProfile()
        profile.skinType = skinType
        saveUserProfile(profile)
        print("🔄 [UserDefaultManager] Skin type updated to: \(skinType.title)")
    }
    
    /// SPF 레벨 업데이트
    func updateSPFLevel(_ spfLevel: SPFLevel) {
        var profile = loadUserProfile()
        profile.spfLevel = spfLevel
        saveUserProfile(profile)
        print("🔄 [UserDefaultManager] SPF level updated to: \(spfLevel.displayTitle)")
    }
    
    /// 사용자 프로필 삭제
    func clearUserProfile() {
        userDefaults.removeObject(forKey: Keys.userProfile)
        print("🗑️ [UserDefaultManager] User profile cleared")
    }
    
    // MARK: - Onboarding Management
    
    /// 온보딩 완료 상태 저장
    func setOnboardingCompleted(_ completed: Bool) {
        userDefaults.set(completed, forKey: Keys.isOnboardingCompleted)
        print("📝 [UserDefaultManager] Onboarding completed: \(completed)")
    }
    
    /// 온보딩 완료 상태 확인
    func isOnboardingCompleted() -> Bool {
        return userDefaults.bool(forKey: Keys.isOnboardingCompleted)
    }
    
    /// 첫 실행 여부 확인
    func isFirstLaunch() -> Bool {
        let isFirst = !userDefaults.bool(forKey: Keys.isFirstLaunch)
        if isFirst {
            userDefaults.set(true, forKey: Keys.isFirstLaunch)
        }
        return isFirst
    }
    
    // MARK: - Debug Methods
    
    /// 저장된 모든 데이터 출력
    func printAllStoredData() {
        print("📊 [UserDefaultManager] === Stored Data ===")
        
        let profile = loadUserProfile()
        print("   - Skin Type: \(profile.skinType.title)")
        print("   - SPF Level: \(profile.spfLevel.displayTitle)")
        print("   - Onboarding Completed: \(isOnboardingCompleted())")
        print("   - Is First Launch: \(isFirstLaunch())")
        
        print("✅ [UserDefaultManager] Data dump completed")
    }
    
    /// 모든 데이터 초기화
    func resetAllData() {
        userDefaults.removeObject(forKey: Keys.userProfile)
        userDefaults.removeObject(forKey: Keys.isOnboardingCompleted)
        userDefaults.removeObject(forKey: Keys.isFirstLaunch)
        print("🔄 [UserDefaultManager] All data reset")
    }
}
