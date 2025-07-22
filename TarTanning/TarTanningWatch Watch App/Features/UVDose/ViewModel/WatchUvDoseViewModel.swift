//
//  UvDoseStatusViewModel.swift
//  TarTanningWatch Watch App
//
//  Created by taeni on 7/18/25.
//

import SwiftUI
import WatchConnectivity

@Observable
class WatchUvDoseViewModel {
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

    var uvIndex: Int = 0
    var percentage: Int = 0
    var uvLevelText: String = "알 수 없음"
    var uvLevel: UVLevel = .safe
    var location: String = "위치 정보 없음"

    init() {
        WatchConnectivityManager.shared.receivedContextPublisher
            .sink { [weak self] context in
                guard let self = self else { return }
                self.updateFrom(context: context)
            }
    }

    private func updateFrom(context: [String: Any]) {
        if let index = context["uvIndex"] as? Int {
            self.uvIndex = index
        }
        if let percent = context["percentage"] as? Int {
            self.percentage = percent
        }
        if let level = context["uvLevel"] as? String {
            self.uvLevelText = level
        }
        if let levelRaw = context["uvLevelCode"] as? String,
           let parsed = UVLevel(rawValue: levelRaw) {
            self.uvLevel = parsed
        }
        if let location = context["location"] as? String {
            self.location = location
        }
    }
}

extension WatchUvDoseViewModel {
    static var mock: WatchUvDoseViewModel {
        let viewModel = WatchUvDoseViewModel()
        viewModel.uvIndex = 6
        viewModel.percentage = 55
        viewModel.uvLevelText = "주의"
        viewModel.uvLevel = .caution
        viewModel.location = "포항시"
        return viewModel
    }
}
