////
////  BezierView.swift
////  TarTanning
////
////  Created by 강진 on 7/17/25.
////
//
//import SwiftUI
//
//struct BezierView: View {
//  
//  @State var openTimer = false
//  @State var medRate: CGFloat = 0.73
//  @State var medColor: UIColor = .orange //MEDViewModel에 medrate에 따른 컬러값/'주의', '안전', '위험' 문구추가해주세요...
//  
//  class totalMEDBezierView: UIView {
//    override init(frame: CGRect) {
//      super.init(frame: frame)
//    }
//    required init?(coder: NSCoder) {
//      fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func draw(_ rect: CGRect) {
//      let path = UIBezierPath(arcCenter: CGPoint(x: 100, y: 100),
//                              radius: 180 / 2.0, startAngle: .pi,
//                              endAngle: 2 * .pi,
//                              clockwise: true)
//      UIColor.clear.setFill()
//      UIColor.systemGray4.setStroke()
//      path.lineWidth = 10
//      path.lineCapStyle = .round
//      path.stroke()
//      path.fill()
//    }
//  }
//  
//  class todayMEDBezierView: UIView {
//    var medRate: CGFloat
//    var medColor: UIColor
//
//    init(frame: CGRect, medRate: CGFloat, medColor: UIColor) {
//        self.medRate = medRate
//        self.medColor = medColor
//        super.init(frame: frame)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func draw(_ rect: CGRect) {
//        let path = UIBezierPath(arcCenter: CGPoint(x: 100, y: 100),
//                                radius: 180 / 2.0, startAngle: .pi,
//                                endAngle: (1 + medRate ) * .pi,
//                                clockwise: true)
//        UIColor.clear.setFill()
//        medColor.setStroke()
//        path.lineWidth = 10
//        path.lineCapStyle = .round
//        path.stroke()
//        path.fill()
//    }
//  }
//  
//  struct totalMEDBezierUIViewRepresentable: UIViewRepresentable {
//    func makeUIView(context: Context) -> UIView {
//      let bezierView = totalMEDBezierView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
//      bezierView.backgroundColor = .clear
//      return bezierView
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {}
//  }
//  struct todayMEDBezierUIViewRepresentable: UIViewRepresentable {
//    var medRate: CGFloat
//    var medColor: UIColor
//
//    func makeUIView(context: Context) -> UIView {
//      let bezierView = todayMEDBezierView(frame: CGRect(x: 0, y: 0, width: 200, height: 200), medRate: medRate, medColor: medColor)
//      bezierView.backgroundColor = .clear
//      return bezierView
//    }
//
//    func updateUIView(_ uiView: UIView, context: Context) {}
//  }
//  
//  
//  var body: some View {
//    if openTimer {
//      TimerView()
//    } else {
//      
//      ZStack {
//        Rectangle()
//          .frame(width: 353, height: 317)
//          .foregroundColor(.white)
//        
//        VStack{
//          ZStack{
//            totalMEDBezierUIViewRepresentable()
//              .frame(width: 200, height: 110)
//            todayMEDBezierUIViewRepresentable(medRate: medRate, medColor: medColor)
//              .frame(width: 200, height: 110)
//            VStack{
//              Text("MED")
//                .font(.system(size:15))
//                .foregroundColor(.gray.opacity(0.5))
//                .padding(.top, 50)
//              Text(String(format: "%.0f%%", medRate * 100))
//                .font(.system(size:28))
//                .foregroundColor(.orange)
//                .bold()
//            }
//          }
//          .padding(10)
//          
//          Text("지금은 자외선으로부터 주의해요!")
//            .font(.system(size:20))
//            .bold()
//          Text("100%가 되면 야외활동을 자제해주세요!")
//            .font(.system(size:14))
//            .foregroundColor(.gray)
//          Button(action: {openTimer = true}) {
//            Label("선크림 모드", systemImage: "cloud.sun")
//              .bold()
//          }
//          .frame(width: 140, height: 35)
//          .background(Color.gray.opacity(0.05))
//          .cornerRadius(20)
//          .padding()
//        }
//        
//      }
//      UVSummaryView()
//    }
//    
//    
//  }
//}
//
//#Preview {
//  BezierView()
//}
