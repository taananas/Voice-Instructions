//
//  ScrubbingBarView.swift
//  Voice Instructions
//
//

import SwiftUI

struct ScrubbingBarView: View {
    let significanceValue: CGFloat = 1000
    var duration: CGFloat = 160
    @Binding var time: Double
    let onChangeTime: (Double) -> Void
    var body: some View {
        
        InfinteHScrollView(alignment: .center, onChange: setTime){
            imagesSection
        }
        .frame(height: 80)
        .background(Color.black.opacity(0.25))
        .overlay {
            LinearGradient(colors: [.black.opacity(0.25), .clear], startPoint: .trailing, endPoint: .center)
                .allowsHitTesting(false)
            LinearGradient(colors: [.black.opacity(0.25), .clear], startPoint: .leading, endPoint: .center)
                .allowsHitTesting(false)
        }
    }
}

struct ScrubbingBarView_Previews: PreviewProvider {

    static var previews: some View {
        TestView()
    }
}


extension ScrubbingBarView{
    private var imagesSection: some View{
        HStack(spacing: 0){
            ForEach(1...8, id: \.self) { _ in
                Image("scrubbingImage")
            }
        }
    }
    
    private func setTime(dragOffset: CGFloat, totalOffset: CGFloat){
        
        let maxOffset = duration * 3
        let offset = max(min((totalOffset + dragOffset), maxOffset), -maxOffset) / significanceValue
        let ratio = offset / maxOffset
        let valueTime = time + duration * ratio
        let newTime = max(min(valueTime, duration), 0)
        
        time = (newTime * 100).rounded() / 100
        
        onChangeTime(time)
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
