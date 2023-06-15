//
//  InternalSlider.swift
//  Voice Instructions
//
//

import SwiftUI



struct InternalSlider<V>: View where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {

    // MARK: - Value
    // MARK: Private
    @Binding private var value: V
    private let bounds: ClosedRange<V>
    private let step: V.Stride
    private var color: Color
    private var width: CGFloat
    let height: CGFloat

    @State private var ratio: CGFloat   = 0
    @State private var startX: CGFloat? = nil
    
    let onChange: () -> Void

    // MARK: - Initializer
    init(value: Binding<V>,
         in bounds: ClosedRange<V>,
         height: CGFloat = 60,
         width: CGFloat = 8,
         step: V.Stride = 1,
         color: Color = .red,
         onChange: @escaping () -> Void) {
        
        _value  = value
        self.onChange = onChange
        self.bounds = bounds
        self.height = height
        self.step = step
        self.color = color
        self.width = width
    }


    // MARK: - View
    // MARK: Public
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .center) {
                // Thumb
                Capsule()
                    .foregroundColor(color)
                    .frame(width: width, height: height)
                    .offset(x: (proxy.size.width - width) * ratio)
                    .gesture(DragGesture(minimumDistance: 0)
                                .onChanged({
                                    updateStatus(value: $0, proxy: proxy)
                                    onChange()
                                })
                                .onEnded {_ in startX = nil})
            }
            .frame(height: height, alignment: .center)
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                                    .onChanged({ update(value: $0, proxy: proxy) }))
            .onAppear {
                ratio = min(1, max(0,CGFloat(value / bounds.upperBound)))
            }
            
            .onChange(of: value) { newValue in
                withAnimation(.easeIn(duration: 0.1)){
                    ratio = min(1, max(0,CGFloat(newValue / bounds.upperBound)))
                }
            }
            .animation(.default, value: ratio)
        }
    }


    // MARK: - Function
    // MARK: Private
    private func updateStatus(value: DragGesture.Value, proxy: GeometryProxy) {
        guard startX == nil else { return }
    
        let delta = value.startLocation.x - (proxy.size.width - width) * ratio
        startX = (width < value.startLocation.x && 0 < delta) ? delta : value.startLocation.x
    }

    private func update(value: DragGesture.Value, proxy: GeometryProxy) {
        guard let x = startX else { return }
        startX = min(width, max(0, x))
    
        var point = value.location.x - x
        let delta = proxy.size.width - width
    
        // Check the boundary
        if point < 0 {
            startX = value.location.x
            point = 0
        
        } else if delta < point {
            startX = value.location.x - delta
            point = delta
        }
    
        // Ratio
        var ratio = point / delta
    
    
        // Step
        if step != 1 {
            let unit = CGFloat(step) / CGFloat(bounds.upperBound - bounds.lowerBound)
        
            let remainder = ratio.remainder(dividingBy: unit)
            if remainder != 0 {
                ratio = ratio - CGFloat(remainder)
            }
        }
    
        self.ratio = ratio
        let newValue = V(bounds.upperBound - bounds.lowerBound) * V(ratio)
        self.value = round(newValue * 1000) / 1000
    }
}
struct StickerSliderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack{
            InternalSlider(value: .constant(40), in: 10...100) { }
                .frame(height: 60)
                .background(Color.secondary)
                .padding()
        }
    }
}




