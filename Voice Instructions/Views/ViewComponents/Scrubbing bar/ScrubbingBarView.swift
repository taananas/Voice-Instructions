//
//  ScrubbingBarView.swift
//  Voice Instructions
//
//  Created by Bogdan Zykov on 08.06.2023.
//

import SwiftUI

struct ScrubbingBarView: View {
    let significanceValue: CGFloat = 10
    var duration: CGFloat = 60
    @Binding var time: Double
    var body: some View {
        VStack {
            InfinteHScrollView(alignment: .center){
                    ForEach(1...10, id: \.self) { _ in
                        cellView
                    }
            } onChange: { totalOffset in
                let value = (totalOffset / significanceValue) / 10
                let newTime = duration + value
                time = min(max(newTime, 0), duration)
            }
            Text("\(duration)")
                .foregroundColor(.white)
        }
        .frame(height: 80)
        .background(Color.black)
    }
}

struct ScrubbingBarView_Previews: PreviewProvider {
    @State static var time: Double = 0
    static var previews: some View {
        ZStack{
            Color.black
            ScrubbingBarView(duration: 60, time: $time)
        }
    }
}

extension ScrubbingBarView{
    private var cellView: some View{
        HStack(spacing: 12){
            ForEach(1...19, id: \.self) { index in
                Rectangle()
                    .opacity(index == 19 ? 0 : 1)
                    .frame(width: 2, height: (index % 5 == 0) || (index == 1) ? 25 : 16)
                    .foregroundColor(index == 10 ? .red : .white)
            }
            .frame(height: 80)
            .background(Color.black)
            .contentShape(Rectangle())
        }
    }
}
