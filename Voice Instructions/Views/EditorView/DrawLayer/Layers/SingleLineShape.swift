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
        
        LineShape(startPoint: shape.startLocation, endPoint: shape.endLocation, isArrow: shape.type == .arrow)
            .stroke(shape.color, lineWidth: 4)
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
        
//        ShapesLayerView()
//            .environmentObject(VideoLayerManager())
        
        VStack {
            SingleLineShape(shape: .constant(.init(type: .line, location: .init(x: 50, y: 450), color: .red, endLocation: .init(x: 100, y: 100)))){}
            SingleLineShape(shape: .constant(.init(type: .arrow, location: .init(x: 50, y: 250), color: .red, endLocation: .init(x: 100, y: 100)))){}
        }
    }
}


extension SingleLineShape{
    
    private var locationDrag: some Gesture {
        DragGesture()
            .updating($startLocation) { (value, startLocation, transaction) in
                if !shape.isActive {return}
                startLocation = startLocation ?? value.location
            }
            .onChanged { value in
                if !shape.isActive {return}
                var newLocation = startLocation ?? .zero
                newLocation.x += value.translation.width
                newLocation.y += value.translation.height
                location = newLocation
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

struct LineShape: Shape {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var isArrow: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        
        
        if isArrow{
            
            // Рассчитываем угол между линией и осью X
            let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
            let weight: CGFloat = 10
            // Рассчитываем координаты вершин треугольника
            let firstPoint = CGPoint(x: endPoint.x - 10 * cos(angle - .pi / 6), y: endPoint.y - 10 * sin(angle - .pi / 6))
            let secondPoint = endPoint
            let thirdPoint = CGPoint(x: endPoint.x - 10 * cos(angle + .pi / 6), y: endPoint.y - 10 * sin(angle + .pi / 6))

            // Добавляем треугольник в путь
            path.addLine(to: firstPoint)
            path.addLine(to: thirdPoint)
            path.addLine(to: secondPoint)

            
//            let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
//            let arrowLength: CGFloat = min(abs(endPoint.x - startPoint.x), abs(endPoint.y - startPoint.y))
//            let arrowWidth: CGFloat = 8
//
//            let endPoint1 = CGPoint(x: endPoint.x - arrowLength * cos(angle) + arrowWidth * cos(angle + .pi/2), y: endPoint.y - arrowLength * sin(angle) + arrowWidth * sin(angle + .pi/2))
//            let endPoint2 = CGPoint(x: endPoint.x - arrowLength * cos(angle) + arrowWidth * cos(angle - .pi/2), y: endPoint.y - arrowLength * sin(angle) + arrowWidth * sin(angle - .pi/2))
//
//            path.addLine(to: endPoint1)
//            path.move(to: endPoint)
//            path.addLine(to: endPoint2)
        }

        return path
    }
}


struct Triangle: Shape {
    var angle: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tipPoint = CGPoint(x: rect.maxX, y: rect.midY)
        let basePoint1 = CGPoint(x: rect.minX, y: rect.minY)
        let basePoint2 = CGPoint(x: rect.minX, y: rect.maxY)
        
        path.move(to: tipPoint)
        path.addLine(to: basePoint1)
        path.addLine(to: basePoint2)
        path.addLine(to: tipPoint)
        path = path.applying(CGAffineTransform(rotationAngle: angle))
        return path
    }
}

