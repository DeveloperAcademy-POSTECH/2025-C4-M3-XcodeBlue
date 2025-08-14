//
//  CoreLocationManager.swift
//  TarTanning
//
//  Created by Jun on 8/14/25.
//

import CoreLocation
import Foundation

final class CoreLocationManager: NSObject {
    static let shared = CoreLocationManager()

    private let locationManager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<LocationAuthStatus, Never>?
    private var locationContinuations: [CheckedContinuation<CLLocation, Error>] = []

    var authorizationStatus: LocationAuthStatus {
        convertToLocationAuthStatus(locationManager.authorizationStatus)
    }

    var isLocationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
    /// Always 권한 보유 여부 확인
    /// 반환값: Bool (Always 권한 보유 여부)
    var hasAlwaysAuthorization: Bool {
        locationManager.authorizationStatus == .authorizedAlways
    }

    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        locationManager.distanceFilter = 1000
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    private func convertToLocationAuthStatus(_ status: CLAuthorizationStatus) -> LocationAuthStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorizedWhenInUse, .authorizedAlways:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .notAvailable
        }
    }
}

// MARK: - Authorization Management
extension CoreLocationManager {
    /// 사용자에게 When In Use 권한 요청 후 결과 반환
    /// 반환값: LocationAuthStatus (권한 요청 결과)
    func requestWhenInUseAuthorization() async -> LocationAuthStatus {
        let currentStatus = authorizationStatus
        if currentStatus != .notDetermined {
            return currentStatus
        }

        return await withCheckedContinuation { continuation in
            self.authorizationContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    /// 사용자에게 Always 권한 요청 후 결과 반환 (백그라운드 위치 업데이트용)
    /// 반환값: LocationAuthStatus (권한 요청 결과)
    func requestAlwaysAuthorization() async -> LocationAuthStatus {
        let currentStatus = authorizationStatus
        if currentStatus == .authorized {
            return currentStatus
        }

        return await withCheckedContinuation { continuation in
            self.authorizationContinuation = continuation
            locationManager.requestAlwaysAuthorization()
        }
    }
}

// MARK: - Location Services  
extension CoreLocationManager {
    /// 현재 위치 조회 (일회성)
    /// 반환값: CLLocation (위도, 경도, 정확도 등 포함)
    /// 오류: LocationError (권한 없음, 서비스 비활성화 등)
    func getCurrentLocation() async throws -> CLLocation {
        guard isLocationServicesEnabled else {
            throw LocationError.servicesDisabled
        }

        let status = authorizationStatus
        guard status.isAuthorized else {
            throw LocationError.permissionDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuations.append(continuation)
            locationManager.requestLocation()
        }
    }

    /// 위치 좌표를 주소 정보로 변환 (Reverse Geocoding)
    /// 매개변수: CLLocation (위도, 경도 정보)
    /// 반환값: [CLPlacemark] 배열 (도시, 국가, 주소 등 포함)
    /// 오류: LocationError.geocodingFailed
    func reverseGeocode(location: CLLocation) async throws -> [CLPlacemark] {
        let geocoder = CLGeocoder()
        do {
            return try await geocoder.reverseGeocodeLocation(location)
        } catch {
            throw LocationError.geocodingFailed(error)
        }
    }
}

// MARK: - Background Location Monitoring
extension CoreLocationManager {
    /// 백그라운드 위치 모니터링 시작 (도시 변경시에만 업데이트)
    /// 오류: LocationError (권한 없음, 서비스 비활성화, Always 권한 필요 등)
    func startMonitoringSignificantLocationChanges() throws {
        guard isLocationServicesEnabled else {
            throw LocationError.servicesDisabled
        }
        
        // Always 권한 전용 체크
        guard hasAlwaysAuthorization else {
            if locationManager.authorizationStatus == .authorizedWhenInUse {
                throw LocationError.onlyWhenInUseGranted
            } else {
                throw LocationError.needsAlwaysPermission
            }
        }
        
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    /// 백그라운드 위치 모니터링 중지
    func stopMonitoringSignificantLocationChanges() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    /// 위치 모니터링 가능 여부 확인
    /// 반환값: Bool (모니터링 지원 여부)
    var isMonitoringAvailable: Bool {
        CLLocationManager.significantLocationChangeMonitoringAvailable()
    }
}

// MARK: - CLLocationManagerDelegate
extension CoreLocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = convertToLocationAuthStatus(manager.authorizationStatus)
        authorizationContinuation?.resume(returning: status)
        authorizationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        locationContinuations.forEach { $0.resume(returning: location) }
        locationContinuations.removeAll()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuations.forEach { $0.resume(throwing: LocationError.noLocationFound) }
        locationContinuations.removeAll()
    }
}
