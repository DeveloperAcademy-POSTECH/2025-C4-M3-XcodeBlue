//
//  WatchSyncTestView.swift
//  TarTanningWatch Watch App
//
//  Created by Jun on 7/15/25.
//

import SwiftUI
import Combine

@MainActor
class WatchSyncTestViewModel: ObservableObject {
    @Published var receivedUVIndex: Double = 0.0
    @Published var receivedMEDValue: Double = 0.0
    @Published var isFeatureOn: Bool = false
    @Published var lastUpdated: String = "대기 중..."

    private var isUpdatingFromRemote = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        WatchConnectivityManager.shared.receivedContextPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                self?.update(from: context)
            }
            .store(in: &cancellables)
            
        $isFeatureOn
            .dropFirst()
            .sink { [weak self] isOn in
                guard let self = self, !self.isUpdatingFromRemote else { return }
                self.sendMessageToPhone(key: "isFeatureOn", value: isOn)
            }
            .store(in: &cancellables)
            
        WatchConnectivityManager.shared.receivedMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                if let isOn = message["isFeatureOn"] as? Bool {
                    self?.isUpdatingFromRemote = true
                    self?.isFeatureOn = isOn
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self?.isUpdatingFromRemote = false
                    }
                }
            }
            .store(in: &cancellables)
            
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WatchConnectivityManager.shared.checkLastReceivedContext()
        }
    }
    
    private func update(from context: [String: Any]) {
        self.isUpdatingFromRemote = true
        
        if let uvIndex = context["uvIndex"] as? Double {
            self.receivedUVIndex = uvIndex
        }
        if let medValue = context["medValue"] as? Double {
            self.receivedMEDValue = medValue
        }
        if let isOn = context["isFeatureOn"] as? Bool {
            self.isFeatureOn = isOn
        }
        
        self.lastUpdated = "업데이트: \(Date().formatted(date: .omitted, time: .standard))"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isUpdatingFromRemote = false
        }
    }
    
    private func sendMessageToPhone(key: String, value: Any) {
        WatchConnectivityManager.shared.sendMessageToPhone([key: value])
    }
}

struct WatchSyncTestView: View {
    @StateObject private var viewModel = WatchSyncTestViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("수신된 데이터")
                
                HStack {
                    Text("UV 지수:")
                    Text(String(format: "%.1f", viewModel.receivedUVIndex))
                }
                
                HStack {
                    Text("MED 값:")
                    Text(String(format: "%.1f", viewModel.receivedMEDValue))
                }
                
                Divider()
                
                Toggle("기능 On/Off (양방향)", isOn: $viewModel.isFeatureOn)
                
                Text(viewModel.lastUpdated)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Watch 테스트")
        .onAppear {
            WatchConnectivityManager.shared.activateSession()
        }
    }
}
