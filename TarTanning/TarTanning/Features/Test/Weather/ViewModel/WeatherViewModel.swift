//
//  WeatherViewModel.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import CoreLocation
import Foundation

@MainActor
class WeatherViewModel: ObservableObject {

    @Published var isLoading = false

    // 시드니 위치 정보
    private let poHangLocation = CLLocation(
        latitude: 36.019627041036635,  // 포항 위도
        longitude: 129.34578962547744  // 포항 경도
    )

    func fetchSydneyUVIndex() {
        print("🌍 포항 UV 지수 확인 시작...")
        print(
            "📍 위치: 포항 (위도: \(poHangLocation.coordinate.latitude), 경도: \(poHangLocation.coordinate.longitude))"
        )

        isLoading = true

        Task {
            print("⏳ WeatherKitManager를 통해 UV 지수 요청 중...")

            // WeatherKitManager를 사용해서 시드니의 UV 지수 가져오기
            if let uvInfo = await WeatherKitManager.shared.fetchUVInfo(
                for: poHangLocation
            ) {
                print("✅ UV 지수 가져오기 성공!")
                print("📊 UV 지수: \(uvInfo.value)")
                print("📝 UV 지수 카테고리: \(uvInfo.category)")
                print("🕐 시간: \(Date())")

            } else {
                print("❌ UV 지수를 가져올 수 없습니다.")
                print("🔍 가능한 원인:")
                print("   - 네트워크 연결 문제")
                print("   - WeatherKit 권한 문제")
                print("   - 위치 정보 오류")
            }

            isLoading = false
            print("🏁 포항 UV 지수 확인 완료\n")
        }
    }
}
