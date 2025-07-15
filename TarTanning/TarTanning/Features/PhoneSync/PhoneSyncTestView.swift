//
//  PhoneSyncTestView.swift
//  TarTanning
//
//  Created by Jun on 7/15/25.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class PhoneSyncTestViewModel: ObservableObject {
    @Published var uvIndexInput: Double = 6.0
    @Published var medValueInput: Double = 150.5
    
    // 워치 정보 요청/수신용 프로퍼티
    @Published var watchInfo: String = ""
    @Published var errorMessage: String? = nil
    @Published var isLoadingInfo: Bool = false
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        Publishers.CombineLatest($uvIndexInput, $medValueInput)
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] (uvIndex, medValue) in
                self?.sendContextToWatch(uvIndex: uvIndex, medValue: medValue)
            }
            .store(in: &cancellables)
    }

    /// 슬라이더 값을 Watch로 전송합니다.
    private func sendContextToWatch(uvIndex: Double, medValue: Double) {
        let context: [String: Any] = ["uvIndex": uvIndex, "medValue": medValue]
        WatchConnectivityManager.shared.sendContext(context)
    }
    
    /// Watch에 기기 정보를 요청합니다.
    func requestWatchInfo() {
        self.isLoadingInfo = true
        self.errorMessage = nil
        self.watchInfo = ""
        
        Task {
            do {
                let deviceInfo = try await WatchConnectivityManager.shared.requestWatchDeviceInfo()
                let model = deviceInfo["watchModel"] as? String ?? "N/A"
                let version = deviceInfo["watchOSVersion"] as? String ?? "N/A"
                self.watchInfo = "모델: \(model), OS: \(version)"
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoadingInfo = false
        }
    }
}

struct PhoneSyncTestView: View {
    @StateObject private var viewModel = PhoneSyncTestViewModel()
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("UV 지수")
                    Text(String(format: "%.1f", viewModel.uvIndexInput))
                }
                Slider(value: $viewModel.uvIndexInput, in: 0...12, step: 0.1)
            }
            
            VStack {
                HStack {
                    Text("MED 값")
                    Text(String(format: "%.1f", viewModel.medValueInput))
                }
                Slider(value: $viewModel.medValueInput, in: 0...1000, step: 0.5)
            }
            
            VStack {
                Button(action: {
                    viewModel.requestWatchInfo()
                }) {
                    if viewModel.isLoadingInfo {
                        ProgressView()
                    } else {
                        Text("페어링 된 Watch 정보 가져오기")
                    }
                }
                .disabled(viewModel.isLoadingInfo)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
                
                if !viewModel.watchInfo.isEmpty {
                    Text(viewModel.watchInfo)
                }
            }
        }
        .padding()
        .onAppear {
            WatchConnectivityManager.shared.activateSession()
        }
    }
}
