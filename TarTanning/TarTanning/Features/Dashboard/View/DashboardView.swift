//
//  DashboardView.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                DashboardTitleView()
                
                DashboardUVDoseView()
                
                DashboardSummaryMetricsView()
            }
        }
//        TabView {
//            DashboardContentView()
//                .tabItem {
//                    Image(systemName: "list.dash")
//                    Text("대시보드")
//                }
//
//            //Text -> 설정view로 바꿔야 함
//            Text("내용2")
//                .tabItem {
//                    Image(systemName: "gear")
//                    Text("설정")
//                }
//        }
    }
}

struct DashboardContentView: View {

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            Color.gray.opacity(0.1).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading) {

                    DashboardUVProgressView()
                    
                    VStack(alignment: .leading) {
                        Text("대시보드")
                            .font(.system(size: 28))
                            .bold()
                        Text(formattedDate)
                    }
                    .padding(.vertical)

                    // MED, 선크림 모드 영역
//                    BezierView()

                    // 주간 요약 영역
                    VStack(alignment: .leading) {
                        Text("주간 요약")
                            .font(.system(size: 18))
                            .bold()
                    }
                    ZStack {
                        Rectangle()
                            .frame(width: 353, height: 308)
                            .foregroundColor(.white)
                            .cornerRadius(20)

                        // 데이터 값이 있으면 여기 주간 요약 list 띄우고, 없으면 아래 대로 보여줘야 함

                        VStack {
                            Image(systemName: "face.smiling.inverse")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.blue)
                            Text("아직 주간 데이터가 없어요.")
                                .foregroundColor(.gray)
                                .font(.system(size: 20))
                                .bold()
                                .padding(5)
                        }
                    }

                    // ArticleView 넣어야 함
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
