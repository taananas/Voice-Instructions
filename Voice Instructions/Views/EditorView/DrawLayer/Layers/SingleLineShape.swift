//
//  SingleLineShape.swift
//  Voice Instructions
//
//  Created by Bogdan Zykov on 16.06.2023.
//

import SwiftUI

struct SingleLineShape: View {
    @GestureState private var startLocation: CGPoint? = nil
    @State var location: CGPoint? = nil
    @Binding var shape: DragShape
    let onSelected: () -> Void
    var body: some View {
        
        LineShape(startPoint: shape.startLocation, endPoint: shape.endLocation, color: shape.color)
            .overlay {
                if shape.isActive{
                    Circle()
                        .stroke(shape.color, style: .init(lineWidth: 3, dash: [5]))
                        .frame(width: 20, height: 20)
                        .position(shape.startLocation)
                        .gesture(dragForPoint(isStartPoint: true))
                    
                    Circle()
                        .stroke(shape.color, style: .init(lineWidth: 3, dash: [5]))
                        .frame(width: 20, height: 20)
                        .position(shape.endLocation)
                        .gesture(dragForPoint(isStartPoint: false))
                }
            }
            .positionOptionally(location)
            .padding(10)
            .gesture(locationDrag)
            .onTapGesture {
                if !shape.isActive{
                    onSelected()
                    shape.isActive = true
                }
            }
    }

}

struct SingleLineShape_Previews: PreviewProvider {
    static var previews: some View {
        SingleLineShape(shape: .constant(.init(type: .line, location: .init(x: 50, y: 450), color: .red, endLocation: .init(x: 100, y: 100)))){}
    }
}


extension SingleLineShape{
    
    private var locationDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                if !shape.isActive {return}
                var newLocation = startLocation ?? location ?? value.location
                newLocation.x += value.translation.width
                newLocation.y += value.translation.height
                location = newLocation
            }.updating($startLocation) { (value, startLocation, transaction) in
                if !shape.isActive {return}
                startLocation = startLocation ?? location
            }
    }
    
    private func dragForPoint(isStartPoint: Bool) -> some Gesture{
        DragGesture()
            .onChanged { value in
                if isStartPoint{
                    shape.startLocation = value.location
                }else{
                    shape.endLocation = value.location
                }
            }
    }
}

extension SingleLineShape{

    struct LineShape: View{
        
        var startPoint: CGPoint
        var endPoint: CGPoint
        var color: Color
        
        var body: some View{
            Path() { path in
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(color, lineWidth: 4)
        }
    }
}
    


