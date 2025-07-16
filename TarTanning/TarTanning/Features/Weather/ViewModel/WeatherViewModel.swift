//
//  WeatherViewModel.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import CoreLocation
import Foundation
import SwiftUICore

@MainActor
class WeatherViewModel: ObservableObject {

    @Published var isLoading = false
    @ObservedObject var locationManager: LocationManager

    init(locationManager: LocationManager) {
      self.locationManager = locationManager
    }
  
    func fetchUVIndex() {
      guard locationManager.latitude != 0.0 && locationManager.longitude != 0.0 else {
              print("⚠️ 위치 정보가 아직 설정되지 않았습니다.")
              return
          }

        let currentLocation = CLLocation(latitude: locationManager.latitude, longitude: locationManager.longitude)
        print("🌍 현재 위치에서 UV 지수 확인 시작...")
        print("📍 위치: \(locationManager.locality) (위도: \(locationManager.latitude), 경도: \(locationManager.longitude))")

        isLoading = true

        Task {
            print("⏳ WeatherKitManager를 통해 UV 지수 요청 중...")

            // WeatherKitManager를 사용해서 현재 지역의 UV 지수 가져오기
            if let uvInfo = await WeatherKitManager.shared.fetchUVInfo(
                for: currentLocation
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
