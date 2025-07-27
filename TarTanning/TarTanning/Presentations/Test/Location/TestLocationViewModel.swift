//
//  TestLocationVIewModel.swift
//  TarTanning
//
//  Created by J on 7/19/25.
//

import Foundation

@MainActor
final class TestLocationViewModel: ObservableObject {
    @Published var locationInfo: LocationInfo?
    @Published var authStatus: LocationAuthStatus = .notDetermined
    @Published var errorMessage: String?
    
    private let authManager = LocationAuthorizationManager.shared
    private let updateManager = LocationUpdateManager.shared
    
    init() {
        authManager.delegate = self
        updateManager.delegate = self
        authManager.checkAuthorizationStatus()
    }
    
    func requestAuthorization() {
        authManager.requestAuthorization()
    }
    
    func startLocationUpdate() {
        updateManager.startUpdatingLocation()
    }
    
    func stopLocationUpdate() {
        updateManager.stopUpdatingLocation()
    }
}

extension TestLocationViewModel: LocationAuthorizationManagerDelegate {
    func locationAuthorizationDidSucceed() {
        startLocationUpdate()
    }

    func locationAuthorizationStatusDidUpdate(_ status: LocationAuthStatus) {
        authStatus = status
    }

    func locationAuthorizationDidFail(with error: Error) {
        errorMessage = "권한 에러: \(error.localizedDescription)"
    }
}

extension TestLocationViewModel: LocationUpdateManagerDelegate {
    func locationUpdateDidSucceed(_ info: LocationInfo) {
        locationInfo = info
    }

    func locationUpdateDidFail(with error: Error) {
        errorMessage = "위치 에러: \(error.localizedDescription)"
    }
}
