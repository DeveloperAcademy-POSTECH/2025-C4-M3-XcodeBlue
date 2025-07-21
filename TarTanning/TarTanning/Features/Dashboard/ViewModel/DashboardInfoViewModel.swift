//
//  DashboardInfoViewModel.swift
//  TarTanning
//
//  Created by 강진 on 7/21/25.
//

import Foundation

class DashboardInfoViewModel: ObservableObject {
    @Published var information: [InformationSet] = []
    
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        information = [
            InformationSet(title: "자외선 경고", category: "UV", imageName: "TestImage1", explanation: "현재 자외선 수치가 높습니다.", content: "외출 시 자외선 차단제를 꼭 바르세요."),
            InformationSet(title: "비타민 D 시간", category: "Health", imageName: "TestImage2", explanation: "적당한 햇빛 노출 시간입니다.", content: "15분 정도 햇볕을 쬐어보세요.")
        ]
    }
}
