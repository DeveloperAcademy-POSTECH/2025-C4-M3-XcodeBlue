//
//  DashboardInfoViewModel.swift
//  TarTanning
//
//  Created by 강진 on 7/21/25.
//

import Foundation

class DashboardInfoViewModel: ObservableObject {
    @Published var groupedInformation: [String: [SunscreenInfoItem]] = [:]
    @Published var categories: [String] = []
    
    private let loader = SunscreenInfoLoader.shared
    
    init() {
        loadInformation()
    }
    
    func loadInformation() {
        let allInformation = loader.loadSunscreenInfo()
        
        // 카테고리별로 그룹화
        groupedInformation = Dictionary(grouping: allInformation) { $0.category }
        
        // 카테고리 목록 생성 (정렬)
        categories = Array(groupedInformation.keys).sorted()
        
        print("📚 [DashboardInfoViewModel] 정보 로드 완료: \(allInformation.count)개 항목")
        print("📁 [DashboardInfoViewModel] 카테고리: \(categories)")
        print("🗂️ [DashboardInfoViewModel] 카테고리별 그룹화 완료")
    }
}
