//
//  ScrubbingBarView.swift
//  Voice Instructions
//
//

import SwiftUI

struct ScrubbingBarView: View {
    let significanceValue: CGFloat = 1000
    var duration: CGFloat = 12
    @Binding var time: Double
    let onChangeTime: (Double) -> Void
    @State private var lastOffset: CGFloat = .zero
    var body: some View {
    
        InfinityHScrollView(alignment: .center, onChange: setTime){
            imagesSection
        }
        .frame(height: 60)
        .background(Color.clear)
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
