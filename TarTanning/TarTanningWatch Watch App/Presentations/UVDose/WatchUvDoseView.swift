import SwiftUI

struct WatchUvDoseView: View {
    
    @State private var viewModel = WatchUvDoseViewModel()
    @State private var currentTab: Int = 0 // 페이지 인덱스
    // 시간 포맷터 (24시간제, AM/PM 없이)
    
    var body: some View {
        ZStack {
            // 배경 색상
            viewModel.uvLevel.color
                .ignoresSafeArea()

            // 콘텐츠 전체 레이어
            VStack{
                // 중앙 MED 정보
                VStack(spacing: 8) {
                    Text("현재 UV노출량")
                        .font(.caption2)
                        .foregroundColor(.white)

                    Text("\(viewModel.percentage)%")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct VerticalPageIndicator: View {
    let currentIndex: Int
    let totalCount: Int

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<totalCount, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

#Preview {
    WatchUvDoseView()
}
