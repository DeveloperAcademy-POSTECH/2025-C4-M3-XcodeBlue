////
////  TimerView.swift
////  TarTanning
////
////  Created by 강진 on 7/18/25.
////
//
//import SwiftUI
//
//struct TimerView: View {
//    @Binding var isPresented: Bool
//
//    var body: some View {
//        VStack(spacing: 24) {
//            Image(systemName: "cloud.sun")
//                .resizable()
//                .frame(width: 50, height: 35)
//                .foregroundColor(.blue)
//
//            // 여기에 타이머 넣기~
//
//            Text("선크림 타이머")
//                .font(.system(size: 17))
//                .bold()
//            
//            Button {
//                isPresented = false
//            } label: {
//                Text("MED 수치 보기")
//                    .font(.system(size: 15))
//                    .bold()
//                    .frame(width: 130, height: 35)
//                    .background(Color.white)
//                    .cornerRadius(20)
//            }
//        }
//        .frame(maxWidth: .infinity)
//        .frame(height: 280)
//        .background(Color.blue.opacity(0.15))
//        .cornerRadius(20)
//    }
//}
//
////#Preview {
////    TimerView(isPresented: .constant(true))
////}
