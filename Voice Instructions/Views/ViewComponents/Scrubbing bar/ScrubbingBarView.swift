//
//  ScrubbingBarView.swift
//  Voice Instructions
//
//

import SwiftUI

struct ScrubbingBarView: View {
    let significanceValue: CGFloat = 10
    var duration: CGFloat = 60
    @Binding var time: Double
    @State var totalOffset: CGFloat = .zero
    var body: some View {
        
        InfinteHScrollView(alignment: .center){
            HStack(spacing: 0){
                ForEach(1...8, id: \.self) { _ in
                    Image("scrubbingImage")
                }
            }
        } onChange: { totalOffset in
            self.totalOffset = totalOffset
            let value = (totalOffset / significanceValue) / 100
            time = abs(min(min(value, 0), duration))
        }
        .frame(height: 80)
        .background(Color.black)
        .overlay {
            LinearGradient(colors: [.black.opacity(0.3), .clear], startPoint: .trailing, endPoint: .center)
                .allowsHitTesting(false)
            LinearGradient(colors: [.black.opacity(0.3), .clear], startPoint: .leading, endPoint: .center)
                .allowsHitTesting(false)
        }
    }
}

struct ScrubbingBarView_Previews: PreviewProvider {

    static var previews: some View {
        TestView()
    }
}



struct TestView: View{
    @State  var time: Double = 0
    var body: some View{
        ZStack{
            Color.black
            ScrubbingBarView(time: $time)
        }
    }
}
