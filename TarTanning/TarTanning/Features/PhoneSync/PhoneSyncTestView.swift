//
//  PhoneSyncTestView.swift
//  TarTanning
//
//  Created by Jun on 7/15/25.
//

import Combine
import SwiftUI

enum AppleWatchModel {
    case series6
    case series7
    case series8
    case series9
    case se1
    case se2
    case ultra1
    case ultra2
    case series5
    case series4
    case series3
    case series2
    case series1
    case firstGen
    case simulator
    case unknown(String)

    init(identifier: String) {
        // #if-#else 구문을 사용하여 컴파일러 경고를 해결하고 코드 경로를 명확히 분리합니다.
        #if targetEnvironment(simulator)
            self = .simulator
        #else
            switch identifier {
            case "Watch6,1", "Watch6,2", "Watch6,3", "Watch6,4": self = .series6
            case "Watch6,6", "Watch6,7", "Watch6,8", "Watch6,9": self = .series7
            case "Watch6,10", "Watch6,11", "Watch6,12", "Watch6,13": self = .se2
            case "Watch6,14", "Watch6,15", "Watch6,16", "Watch6,17":
                self = .series8
            case "Watch6,18": self = .ultra1
            case "Watch7,1", "Watch7,2", "Watch7,3", "Watch7,4": self = .series9
            case "Watch7,5": self = .ultra2
            case "Watch5,1", "Watch5,2", "Watch5,3", "Watch5,4": self = .series5
            case "Watch5,9", "Watch5,10", "Watch5,11", "Watch5,12": self = .se1
            case "Watch4,1", "Watch4,2", "Watch4,3", "Watch4,4": self = .series4
            case "Watch3,1", "Watch3,2", "Watch3,3", "Watch3,4": self = .series3
            case "Watch2,3", "Watch2,4": self = .series2
            case "Watch2,6", "Watch2,7": self = .series1
            case "Watch1,1", "Watch1,2": self = .firstGen
            default: self = .unknown(identifier)
            }
        #endif
    }

    /// 사용자에게 보여줄 모델명입니다.
    var displayName: String {
        switch self {
        case .series6: return "Apple Watch Series 6"
        case .series7: return "Apple Watch Series 7"
        case .series8: return "Apple Watch Series 8"
        case .series9: return "Apple Watch Series 9"
        case .se1: return "Apple Watch SE (1st generation)"
        case .se2: return "Apple Watch SE (2nd generation)"
        case .ultra1: return "Apple Watch Ultra"
        case .ultra2: return "Apple Watch Ultra 2"
        case .series5: return "Apple Watch Series 5"
        case .series4: return "Apple Watch Series 4"
        case .series3: return "Apple Watch Series 3"
        case .series2: return "Apple Watch Series 2"
        case .series1: return "Apple Watch Series 1"
        case .firstGen: return "Apple Watch (1st generation)"
        case .simulator: return "Apple Watch Simulator"
        case .unknown(let id): return "알 수 없는 기기 (\(id))"
        }
    }

    var supportsDaylightFeature: Bool {
        switch self {
        case .series6, .series7, .series8, .series9, .se2, .ultra1, .ultra2:
            return true
        default:
            return false
        }
    }

    var fullDescription: String {
        let suffix = supportsDaylightFeature ? " (기능 지원)" : " (기능 미지원)"
        return displayName + suffix
    }
}

@MainActor
class PhoneSyncTestViewModel: ObservableObject {
    @Published var uvIndexInput: Double = 6.0
    @Published var medValueInput: Double = 150.5

    @Published var watchInfo: String = ""
    @Published var errorMessage: String?
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

    private func sendContextToWatch(uvIndex: Double, medValue: Double) {
        let context: [String: Any] = ["uvIndex": uvIndex, "medValue": medValue]
        WatchConnectivityManager.shared.sendContext(context)
    }

    func sendInitialState() {
        print("Sending initial state to watch...")
        sendContextToWatch(
            uvIndex: self.uvIndexInput,
            medValue: self.medValueInput
        )
    }

    func requestWatchInfo() {
        self.isLoadingInfo = true
        self.errorMessage = nil
        self.watchInfo = ""

        Task {
            do {
                let deviceInfo = try await WatchConnectivityManager.shared
                    .requestWatchDeviceInfo()
                let modelIdentifier =
                    deviceInfo["watchModel"] as? String ?? "N/A"

                let watchModel = AppleWatchModel(identifier: modelIdentifier)

                let version = deviceInfo["watchOSVersion"] as? String ?? "N/A"

                self.watchInfo =
                    "모델: \(watchModel.fullDescription), OS: \(version)"
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
            viewModel.sendInitialState()
        }
    }
}
