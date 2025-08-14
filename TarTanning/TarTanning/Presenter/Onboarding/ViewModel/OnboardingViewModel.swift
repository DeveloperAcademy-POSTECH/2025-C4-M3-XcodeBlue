//
//  OnboardingViewModel.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    // 임시 선택 상태 (UI용)
    @Published var selectedSkinType: SkinType = .type3
    
    // MARK: - 온보딩 플로우 관리
    @Published var currentStep: OnboardingStep = .watchInfo
    @Published var activeSheet: OnboardingStep? = .startSheet
    
    // MARK: - Location 권한
    @Published var locationStatus: LocationAuthStatus = .notDetermined
    @Published var locationErrorMessage: String?
    
    // MARK: - HealthKit 권한
    private let healthKitAuthorizationManager = HealthKitAuthorizationManager()
    @Published var healthKitStatus: HealthKitAuthStatus = .notDetermined
    @Published var healthKitErrorMessage: String?
    
    // MARK: - Notification 권한
    private let notificationAuthorizationManager = NotificationAuthorizationManager.shared
    @Published var notificationStatus: NotificationAuthStatus = .notDetermined
    @Published var notificationErrorMessage: String?
    
    var isPermissionStepComplete: Bool {
        //        locationStatus == .authorized && healthKitStatus == .authorized
        locationStatus == .authorized && healthKitStatus == .authorized && notificationStatus == .authorized
    }
    
    // 선택된 피부타입 (UI용)
    var selectedSkinTypeForUI: SkinType? {
        selectedSkinType
    }
    
    init() {
        setupDelegates()
        checkAuthorizations()
    }
    
    // MARK: - User Profile Management
    private func setupDelegates() {
        healthKitAuthorizationManager.delegate = self
        notificationAuthorizationManager.delegate = self
    }
    
    private func checkAuthorizations() {
        healthKitAuthorizationManager.checkAuthorizationStatusWithCompletion()
        notificationAuthorizationManager.checkAuthorizationStatus()
    }
    
    // MARK: - 권한 요청
    func requestAllAuthorizations() {
        requestNotificationAuthorization()
        requestHealthKitAuthorization()
    }
    
    private func requestHealthKitAuthorization() {
        Task {
            await healthKitAuthorizationManager.requestAuthorization()
        }
    }
    
    private func requestNotificationAuthorization() {
        notificationAuthorizationManager.requestAuthorization()
    }
    
    // MARK: - 온보딩 흐름 제어
    func nextMainView() {
        switch currentStep {
        case .watchInfo:
            currentStep = .permissionInfo
        case .permissionInfo:
            currentStep = .skinTypeInfo
        case .skinTypeInfo:
            completeOnboarding()
        default:
            break
        }
    }
    
    func proceedIfPermissionsGranted() {
        if currentStep == .permissionInfo {
            nextMainView()
        }
    }
    
    // MARK: - 스킨 타입 선택
    func selectSkinType(_ type: SkinType) {
        selectedSkinType = type
        print("🔄 [OnboardingViewModel] Skin type selected: \(type.title)")
    }
    
    // MARK: - 온보딩 완료
    func completeOnboarding() {
        print("🎉 [OnboardingViewModel] Completing onboarding")
        
        // 1. 사용자 프로필 저장
        let userProfile = UserProfile(
            skinType: selectedSkinType,
            spfLevel: .spf30 // 기본값
        )
        
        print("✅ [OnboardingViewModel] Onboarding completed successfully")
    }
}

extension OnboardingViewModel: HealthKitAuthorizationManagerDelegate {
    func healthKitAuthorizationDidSucceed() {
        healthKitStatus = .authorized
        proceedIfPermissionsGranted()
    }
    
    func healthKitAuthorizationStatusDidUpdate(_ status: HealthKitAuthStatus) {
        healthKitStatus = status
    }
    
    func healthKitAuthorizationDidFail(with error: Error) {
        healthKitStatus = .denied
        healthKitErrorMessage = error.localizedDescription
    }
}

extension OnboardingViewModel: NotificationAuthorizationManagerDelegate {
    func notificationAuthorizationDidUpdate(_ status: NotificationAuthStatus) {
        notificationStatus = status
    }
    
    func notificationAuthorizationDidFail(_ error: Error) {
        notificationStatus = .denied
        notificationErrorMessage = error.localizedDescription
    }
}
