//
//  SingleShapeView.swift
//  Voice Instructions
//
//

import SwiftUI

struct SingleShapeView: View {
    @State private var width: CGFloat = 100
    @State private var height: CGFloat = 100
    @State private var location: CGPoint
    @GestureState private var startLocation: CGPoint? = nil
    @State private var angle: Angle = .degrees(0)
    @Binding var shapeModel: DragShape
    let onSelected: () -> Void
    
    init(shapeModel: Binding<DragShape>, onSelected: @escaping () -> Void){
        self._shapeModel = shapeModel
        self._location = State(wrappedValue: shapeModel.wrappedValue.startLocation)
        self.onSelected = onSelected
    }
    
    var body: some View {

        shapeView
            .foregroundColor(shapeModel.color)
            .overlay(alignment: shapeModel.type == .circle ? .trailing : .bottomTrailing) {
                if shapeModel.isActive{
                    Circle()
                        .stroke(shapeModel.color, style: .init(lineWidth: 3, dash: [5]))
                        .frame(width: 36, height: 36)
                        .contentShape(Circle())
                        .offset(x: 18, y: 18)
                        .gesture(sizeDrag)
                }
            }
//            .overlay(alignment: .bottom) {
//                if shapeModel.isActive{
//                    Rectangle()
//                        .rotation(.degrees(45))
//                        .stroke(shapeModel.color, style: .init(lineWidth: 3, dash: [5]))
//                        .frame(width: 30, height: 30)
//                        .contentShape(Circle())
//                        .offset(y: 15)
//                        .gesture(rotateDrag)
//                }
//            }
            .rotationEffect(angle, anchor: .bottomLeading)
            .frame(width: width, height: height)
            .position(location)
            .gesture(locationDrag)
            .onTapGesture {
                if !shapeModel.isActive{
                    onSelected()
                    shapeModel.isActive = true
                }
            }
    }
    
    private var shapeView: some View{
        Group{
            if shapeModel.type == .circle{
                Circle().stroke(lineWidth: 5)
            }else{
                Rectangle().stroke(lineWidth: 5)
            }
        }
    }
    
    private var locationDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                if !shapeModel.isActive {return}
                var newLocation = startLocation ?? location
                newLocation.x += value.translation.width
                newLocation.y += value.translation.height
                self.location = newLocation
            }.updating($startLocation) { (value, startLocation, transaction) in
                if !shapeModel.isActive {return}
                startLocation = startLocation ?? location
            }
    }
    
    private var sizeDrag: some Gesture{
        DragGesture()
            .onChanged { value in
                width = max(0, width + value.translation.width)
                height = max(0, height + value.translation.height)
            }
    }
    
    private var rotateDrag: some Gesture{
        DragGesture()
            .onChanged{ v in
                let vector = CGVector(dx: v.location.x, dy: v.location.y)
                let angle = Angle(radians: Double(atan2(vector.dy, vector.dx)))
                
                self.angle = angle
            }
           
    }
}

struct SingleShapeView_Previews: PreviewProvider {
    static var previews: some View {
        SingleShapeView(shapeModel: .constant(.init(type: .circle, startLocation: .init(x: 100, y: 100), color: .red))){}
    }
}


struct DragShape: Identifiable{
    
    var id: UUID = UUID()
    var isActive = true
    var type: ShapeType
    var startLocation: CGPoint
    var color: Color
    
    init(type: ShapeType, startLocation: CGPoint, color: Color) {
        self.type = type
        self.startLocation = startLocation
        self.color = color
    }
    
    
    enum ShapeType: Int {
        
        case circle, rectangle
    }
}
