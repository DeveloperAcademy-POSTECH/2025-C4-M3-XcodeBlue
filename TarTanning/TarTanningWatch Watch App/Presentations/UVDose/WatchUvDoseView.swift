import SwiftUI

struct WatchUvDoseView: View {
    
    @State private var viewModel = WatchUvDoseViewModel.mock
    @State private var currentTab: Int = 0 // 페이지 인덱스
    // 시간 포맷터 (24시간제, AM/PM 없이)
    private var currentTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR") // 한국어 설정
        formatter.dateFormat = "HH:mm" // 24시간제 포맷
        return formatter.string(from: Date())
    }
    
    var body: some View {
        ZStack {
            // 배경 색상
            viewModel.uvLevel.color
                .ignoresSafeArea()

            // 콘텐츠 전체 레이어
            VStack{
                // 상단 시간 + 인디케이터
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 16) {
                        Spacer()
                        // 현재 시간 표시
                        // 기존 Text(Date(), style: .time) → 교체
                        Text(currentTime)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        // 세로형 페이지 인디케이터
                        
                        VerticalPageIndicator(currentIndex: currentTab, totalCount: 2)
                    }
                    
                }
                .padding(.trailing, 10)

                Spacer()

                // 중앙 MED 정보
                VStack(spacing: 8) {
                    Text("현재 MED")
                        .font(.caption2)
                        .foregroundColor(.white)

                    Text("\(viewModel.percentage)%")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                    .padding(30)
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
