//
//  HealthKitAuthorizationManager.swift
//  TarTanning
//
//  Created by taeni on 7/15/25.
//

import Foundation
import HealthKit

@MainActor
protocol HealthKitAuthorizationManagerDelegate: AnyObject {
    func healthKitAuthorizationDidSucceed()
    func healthKitAuthorizationDidFail(with error: Error)
    func healthKitAuthorizationStatusDidUpdate(_ status: HealthKitAuthStatus)
}

@MainActor
final class HealthKitAuthorizationManager: ObservableObject {
    weak var delegate: HealthKitAuthorizationManagerDelegate?
    
    private let healthStore = HKHealthStore()
    
    @Published var authorizationStatus: HealthKitAuthStatus = .notDetermined
    @Published var errorMessage: String?
    
    var isAuthorized: Bool {
        authorizationStatus.isAuthorized
    }
    
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    private let typesToRead: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .timeInDaylight)!
    ]
    
    init() {
        checkAuthorizationStatusWithCompletion()
    }
    
    func checkAuthorizationStatusWithCompletion() {
        guard HKHealthStore.isHealthDataAvailable() else {
            updateStatus(.notAvailable, errorMessage: "이 기기에서는 HealthKit을 사용할 수 없습니다")
            return
        }

        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .timeInDaylight)!
        ]

        healthStore.getRequestStatusForAuthorization(toShare: [], read: typesToRead) { [weak self] status, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.updateStatus(.notAvailable, errorMessage: "상태 확인 실패: \(error.localizedDescription)")
                }
                return
            }

            DispatchQueue.main.async {
                switch status {
                case .shouldRequest:
                    self.updateStatus(.notDetermined, errorMessage: "권한이 아직 요청되지 않았습니다")
                case .unnecessary:
                    self.updateStatus(.authorized, errorMessage: nil)
                case .unknown:
                    self.updateStatus(.notDetermined, errorMessage: "권한 상태를 확인할 수 없습니다")
                @unknown default:
                    self.updateStatus(.notDetermined, errorMessage: "알 수 없는 상태입니다")
                }
            }
        }
    }
    
    func requestAuthorization() async {
        guard isHealthDataAvailable else {
            handleAuthorizationError(HealthKitError.notAvailable)
            return
        }
        
        do {
            _ = try await performAuthorizationRequest()
            checkAuthorizationStatusWithCompletion()
            
            if authorizationStatus == .authorized {
                errorMessage = nil
                delegate?.healthKitAuthorizationDidSucceed()
            } else {
                handleAuthorizationError(HealthKitError.authorizationDenied)
            }
        } catch {
            let hkError = error as? HealthKitError ?? HealthKitError.authorizationFailed(error)
            handleAuthorizationError(hkError)
            checkAuthorizationStatusWithCompletion()
        }
    }
    
    private func performAuthorizationRequest() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.authorizationFailed(error))
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    private func updateStatus(_ status: HealthKitAuthStatus, errorMessage: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.authorizationStatus = status
            self.errorMessage = errorMessage
            self.delegate?.healthKitAuthorizationStatusDidUpdate(status)
        }
    }
    
    private func handleAuthorizationError(_ error: HealthKitError) {
        errorMessage = error.localizedDescription
        delegate?.healthKitAuthorizationDidFail(with: error)
    }
}
