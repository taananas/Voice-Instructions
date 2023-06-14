//
//  RangeSlider.swift
//  Voice Instructions
//
//

import SwiftUI

struct RangedSliderView<T: View>: View {
    let currentValue: Binding<ClosedRange<Double>>?
    let sliderBounds: ClosedRange<Double>
    let step: Double
    let onEndChange: () -> Void
    var thumbView: T
        
    init(value: Binding<ClosedRange<Double>>?, bounds: ClosedRange<Double>, step: Double = 1, onEndChange: @escaping () -> Void, @ViewBuilder thumbView: () -> T) {
        self.onEndChange = onEndChange
        self.step = step
        self.currentValue = value
        self.sliderBounds = bounds
        self.thumbView = thumbView()
    }
    
    var body: some View {
        GeometryReader { geomentry in
            sliderView(sliderSize: geomentry.size)
        }
    }
    
        
    @ViewBuilder private func sliderView(sliderSize: CGSize) -> some View {
        let sliderViewYCenter = sliderSize.height / 2
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(.systemGray5).opacity(0.75))
                .frame(height: sliderSize.height)
            ZStack {
                let sliderBoundDifference = sliderBounds.upperBound / step
                let stepWidthInPixel = CGFloat(sliderSize.width) / CGFloat(sliderBoundDifference)
                
                // Calculate Left Thumb initial position
                let leftThumbLocation: CGFloat = currentValue?.wrappedValue.lowerBound == sliderBounds.lowerBound
                    ? 0
                : CGFloat((currentValue?.wrappedValue.lowerBound ?? 0) - sliderBounds.lowerBound) * stepWidthInPixel
                
                // Calculate right thumb initial position
                let rightThumbLocation = CGFloat(currentValue?.wrappedValue.upperBound ?? 1) * stepWidthInPixel
                let height = rightThumbLocation - leftThumbLocation
                // Path between both handles
                
            
                thumbView
                    .frame(width: height, height: sliderSize.height)
                    .position(x: sliderSize.width - (sliderSize.width - leftThumbLocation - height / 2) , y: sliderViewYCenter)
                    
                
                // Left Thumb Handle
                let leftThumbPoint = CGPoint(x: leftThumbLocation, y: sliderViewYCenter)
                thumbSlider(height: sliderSize.height, position: leftThumbPoint, isLeftThumb: true)
                    .highPriorityGesture(DragGesture().onChanged { dragValue in
                        let dragLocation = dragValue.location
                        let xThumbOffset = min(max(0, dragLocation.x), sliderSize.width)
                        
                        let newValue = (sliderBounds.lowerBound) + (xThumbOffset / stepWidthInPixel)
                        if (currentValue?.wrappedValue.upperBound ?? 1) - newValue <= 1 {return}
                        // Stop the range thumbs from colliding each other
                        if newValue < currentValue?.wrappedValue.upperBound ?? 1 {
                            currentValue?.wrappedValue = newValue...(currentValue?.wrappedValue.upperBound ?? 1)
                        }
                    }.onEnded({ _ in
                        onEndChange()
                    }))
                
                
                
                // Right Thumb Handle
                thumbSlider(height: sliderSize.height, position: CGPoint(x: rightThumbLocation, y: sliderViewYCenter), isLeftThumb: false)
                    .highPriorityGesture(DragGesture().onChanged { dragValue in
                        let dragLocation = dragValue.location
                        let xThumbOffset = min(max(CGFloat(leftThumbLocation), dragLocation.x), sliderSize.width)
                        
                        var newValue = xThumbOffset / stepWidthInPixel // convert back the value bound
                        newValue = min(newValue, sliderBounds.upperBound)
                
                        if newValue - (currentValue?.wrappedValue.lowerBound ?? 0) <= 1 {return}
                        
                        // Stop the range thumbs from colliding each other
                        if (newValue > currentValue?.wrappedValue.lowerBound ?? 0) {
                            currentValue?.wrappedValue = (currentValue?.wrappedValue.lowerBound ?? 0)...newValue
                        }
                    }.onEnded({ _ in
                        onEndChange()
                    }))
                lineBetweenThumbs(height: 2, from: leftThumbPoint, to: CGPoint(x: rightThumbLocation, y: sliderViewYCenter))
                    .offset(y: sliderViewYCenter - 1)
                
                lineBetweenThumbs(height: 2, from: leftThumbPoint, to: CGPoint(x: rightThumbLocation, y: sliderViewYCenter))
                    .offset(y: -sliderViewYCenter + 1)
            }
        }
        .compositingGroup()
    }
    
    @ViewBuilder func lineBetweenThumbs(height: CGFloat, from: CGPoint, to: CGPoint) -> some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }.stroke(Color.red, lineWidth: height)
    }
    
    @ViewBuilder func thumbSlider(height: CGFloat, position: CGPoint, isLeftThumb: Bool) -> some View {
        let time = isLeftThumb ? currentValue?.wrappedValue.lowerBound.formatterTimeString() :
        currentValue?.wrappedValue.upperBound.formatterTimeString()
     
        let width: CGFloat = 18
        VStack(spacing: 0) {
            
            CustomCorner(corners: isLeftThumb ? [.bottomLeft, .topLeft] : [.topRight, .bottomRight], radius: 5)
                .frame(width: width, height: height)
                .foregroundColor(.red)
                .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 2)
                .contentShape(Rectangle())
                .overlay(alignment: .top){
                    Text(time ?? "")
                        .font(.callout)
                        .fixedSize()
                        .offset(y: -20)
                }
                .overlay(alignment: .center) {
                    Capsule()
                        .fill(Color.white)
                        .frame(width: 3, height: 40)
                }
        }
        .position(x: position.x + CGFloat((isLeftThumb ? -(width/2) : width/2)), y: position.y)
    }
}

struct RangeSliderView_Previews: PreviewProvider {
    
    static var previews: some View {
        TestSliderView()
            .padding()
    }
}



fileprivate struct TestSliderView: View{
    @State private var value: ClosedRange<Double> = 0...5
    var body: some View{
        RangedSliderView(value: $value, bounds: 1...100, onEndChange: {}, thumbView: {
            
            
            Rectangle()
                .blendMode(.destinationOut)
            InternalSlider(value: .constant(40), in: 10...100, height: 70, width: 6, step: 0.1) {
                
            }
            
        })
            .frame(height: 70)
            .padding()
    }
}



struct CustomCorner: Shape {
    
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        
        return Path(path.cgPath)
    }
}

