//
//  DashboardInfoViewModel.swift
//  TarTanning
//
//  Created by 강진 on 7/21/25.
//

import Foundation

class DashboardInfoViewModel: ObservableObject {
    @Published var information: [InformationItem] = []
    
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        information = [
          InformationItem(title: "자외선 경고",category: "UV", imageName: "SPF", explanation: "현재 자외선 수치가 높습니다.dafjofjfofjweofejofdjofjofdjofdjfpjfjfaofjfqwjfopqjfpoqjeiojoifjwoifjoiwajaoifjwoijiofjwo", content: "대부분의 사람은 햇볕에 노출될 때 선크림을 바르지만, SPF라는 숫자가 정확히 어떤 의미인지는 잘 모릅니다. SPF(Sun Protection Factor)는 **자외선 B(UVB)**로부터 피부를 얼마나 오래 보호할 수 있는지를 나타내는 지수입니다. 쉽게 말하면, 아무 것도 바르지 않은 상태에서 피부가 붉어지기까지 걸리는 시간이 10분이라면, SPF 30은 약 30배 더 오랜 시간(=300분) 동안 자외선으로부터 피부를 보호할 수 있다는 뜻입니다."),
          InformationItem(title: "비타민 D 시간", category: "Health", imageName: "SkinType", explanation: "적당한 햇빛 노출 시간입니다.", content: "15분 정도 햇볕을 쬐어보세요.")
        ]
    }
}
