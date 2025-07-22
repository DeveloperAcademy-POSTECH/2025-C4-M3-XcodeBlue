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
    @AppStorage("selectedSkinType") private var selectedSkinTypeRaw: Int = 3
    @AppStorage("didFinishOnboarding") private var didFinishOnboarding: Bool = false
    
    // MARK: - 온보딩 플로우 관리
    @Published var currentStep: OnboardingStep = .watchInfo
    @Published var activeSheet: OnboardingStep? = .startSheet
    
    // MARK: - Location 권한
    private let locationAuthorizationManager = LocationAuthorizationManager()
    @Published var locationStatus: LocationAuthStatus = .notDetermined
    @Published var locationErrorMessage: String?
    
    // MARK: - HealthKit 권한
    private let heahlthKitAuthorizationManager = HealthKitAuthorizationManager()
    @Published var healthKitStatus: HealthKitAuthStatus = .notDetermined
    @Published var healthKitErrorMessage: String?
    
    // MARK: - Notification 권한
    private let notificationAuthorizationManager = NotificationAuthorizationManager()
    @Published var notificationStatus: NotificationAuthStatus = .notDetermined
    @Published var notificationErrorMessage: String?
    
    var isPermissionStepComplete: Bool {
        //        locationStatus == .authorized && healthKitStatus == .authorized
        locationStatus == .authorized && healthKitStatus == .authorized && notificationStatus == .authorized
    }
    
    var selectedSkinType: SkinType? {
        get { SkinType(rawValue: selectedSkinTypeRaw) }
        set { selectedSkinTypeRaw = newValue?.rawValue ?? 3 }
    }
    
    init() {
        setupDelegates()
        checkAuthorizations()
    }
    
    private func setupDelegates() {
        locationAuthorizationManager.delegate = self
        heahlthKitAuthorizationManager.delegate = self
        notificationAuthorizationManager.delegate = self
    }
    
    private func checkAuthorizations() {
        locationAuthorizationManager.checkAuthorizationStatus()
        heahlthKitAuthorizationManager.checkAuthorizationStatusWithCompletion()
        notificationAuthorizationManager.checkAuthorizationStatus()
    }
    
    // MARK: - 권한 요청
    func requestAllAuthorizations() {
        requestLocationAuthorization()
        requestNotificationAuthorization()
        requestHealthKitAuthorization()
    }
    
    private func requestLocationAuthorization() {
        Task {
            locationAuthorizationManager.requestAuthorization()
        }
    }
    
    private func requestHealthKitAuthorization() {
        Task {
            await heahlthKitAuthorizationManager.requestAuthorization()
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
            didFinishOnboarding = true
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
    }
}

extension OnboardingViewModel: LocationAuthorizationManagerDelegate {
    func locationAuthorizationDidSucceed() {
        locationStatus = .authorized
        
    }
    
    func locationAuthorizationStatusDidUpdate(_ status: LocationAuthStatus) {
        locationStatus = status
    }
    
    func locationAuthorizationDidFail(with error: Error) {
        healthKitStatus = .denied
        locationErrorMessage = error.localizedDescription
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
