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
//  @State var openBezier = false
//  
//  var body: some View {
//    if openBezier {
//      BezierView()
//    } else {
//      
//      ZStack {
//        Rectangle()
//          .frame(width: 353, height: 406)
//          .foregroundColor(.blue.opacity(0.15))
//        
//        VStack{
//          Image(systemName: "cloud.sun")
//            .resizable()
//            .frame(width: 50, height: 35)
//            .foregroundColor(.blue)
//          
//          //여기에 타이머 넣기~
//          
//          Text("선크림 타이머")
//            .font(.system(size:17))
//            .padding(.top, 50)
//            .bold()
//          Button(action: {openBezier = true}) {
//            Text("MED 수치 보기")
//              .font(.system(size:15))
//              .bold()
//          }
//          .frame(width: 130, height: 35)
//          .background(Color.white)
//          .cornerRadius(20)
//          .padding()
//        }
//      }
//      .padding(.bottom)
//    }
//  }
//}
//
//#Preview {
//  TimerView()
//}
