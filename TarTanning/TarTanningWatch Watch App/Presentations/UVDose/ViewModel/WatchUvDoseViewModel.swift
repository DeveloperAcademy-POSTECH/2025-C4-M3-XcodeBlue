//
//  WatchUvDoseViewModel.swift
//  TarTanningWatch Watch App
//
//  Created by taeni on 7/18/25.
//

import SwiftUI
import WatchConnectivity
import Combine

@MainActor
final class WatchUvDoseViewModel: ObservableObject {
    enum UVLevel: String {
        case safe = "안전"
        case caution = "주의"
        case danger = "위험"
        case bad = "매우위험"

        var color: Color {
            switch self {
            case .safe: return .gaugeBackgroundSafe
            case .caution: return .gaugeBackgroundCaution
            case .danger: return .gaugeBackgroundDanger
            case .bad: return .gaugeBackgroundBad
            }
        }
    }
    
    @Published var uvIndex: Int = 0
    @Published var medValue: Double = 0.0
    @Published var uvLevelText: String = "알 수 없음"
    @Published var uvLevel: UVLevel = .safe
    @Published var location: String = "위치 정보 없음"
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSunscreenViewModelObservation()
    }
    
    private func setupSunscreenViewModelObservation() {
        // SunscreenViewModel의 UV 데이터 구독
        SunscreenViewModel.shared.$currentMEDValue
            .receive(on: DispatchQueue.main)
            .sink { [weak self] medValue in
                self?.medValue = medValue
            }
            .store(in: &cancellables)
        
        SunscreenViewModel.shared.$currentUVIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] uvIndex in
                self?.uvIndex = Int(uvIndex)
            }
            .store(in: &cancellables)
        
        SunscreenViewModel.shared.$uvStatusLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] statusLevel in
                self?.uvLevelText = statusLevel
                self?.uvLevel = UVLevel(rawValue: statusLevel) ?? .safe
            }
            .store(in: &cancellables)
        
        SunscreenViewModel.shared.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.location = location
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties for UI
    
    /// MED 값을 백분율로 변환 (기존 percentage 프로퍼티 대체)
    var percentage: Int {
        // MED 값이 실제 누적량이므로, 100을 기준으로 백분율 계산
        // 실제로는 사용자의 피부타입별 maxMED를 기준으로 계산해야 하지만
        // 여기서는 간단히 medValue를 백분율로 표시
        return Int(min(medValue, 100.0))
    }
    
    /// UV 레벨에 따른 색상
    var backgroundColorForLevel: Color {
        return uvLevel.color
    }
}

// MARK: - Mock Data for Preview
extension WatchUvDoseViewModel {
    static var mock: WatchUvDoseViewModel {
        let viewModel = WatchUvDoseViewModel()
        viewModel.uvIndex = 6
        viewModel.medValue = 55.0
        viewModel.uvLevelText = "주의"
        viewModel.uvLevel = .caution
        viewModel.location = "포항시"
        return viewModel
    }
    
    /// 테스트용 데이터 설정
    func setupMockData(
        uvIndex: Int = 6,
        medValue: Double = 55.0,
        uvLevel: UVLevel = .caution,
        location: String = "포항시"
    ) {
        self.uvIndex = uvIndex
        self.medValue = medValue
        self.uvLevelText = uvLevel.rawValue
        self.uvLevel = uvLevel
        self.location = location
    }
}
