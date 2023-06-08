//
//  ScrubbingBarView.swift
//  Voice Instructions
//
//

import SwiftUI

struct ScrubbingBarView: View {
    let significanceValue: CGFloat = 100_000
    var duration: CGFloat = 60
    @Binding var time: Double
    let onChangeTime: (Double) -> Void
    var body: some View {
        
        InfinteHScrollView(alignment: .center){
            HStack(spacing: 0){
                ForEach(1...8, id: \.self) { _ in
                    Image("scrubbingImage")
                }
            }
        } onChange: { totalOffset in
            let value = (totalOffset / significanceValue)
            time = min(max(time + value, 0), duration)
            onChangeTime(time)
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
            ScrubbingBarView(time: $time, onChangeTime: {_ in})
        }
    }
}
