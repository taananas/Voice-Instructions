//
//  FreeLineLayerView.swift
//  Voice Instructions
//
//

import SwiftUI

struct FreeLineLayerView: View {
    @EnvironmentObject var layerManager: VideoLayerManager
    var body: some View {
        
        
        ZStack{
            Color.white.opacity(0.0001)
            
            ForEach(layerManager.strokes.indices, id: \.self){index in
            Path(curving: layerManager.strokes[index].points)
                    .stroke(style: .init(lineWidth: 5, lineCap: .round, lineJoin: .round))
                
            }
        }
        
//        Canvas { context, size in
//            for stroke in layerManager.strokes {
//                let path = Path(curving: stroke.points)
//                context.stroke(
//                    path,
//                    with: .color(stroke.color),
//                    style: StrokeStyle(lineWidth: stroke.width,
//                                       lineCap: .round, lineJoin: .round)
//                )
//            }
//        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    layerManager.addLine(value: value)
                }
        )
    }
}

struct FreeLineLayerView_Previews: PreviewProvider {
    static var previews: some View {
        FreeLineLayerView()
            .environmentObject(VideoLayerManager())
    }
}


struct Stroke {
    var points = [CGPoint]()
    var color = Color.red
    var width = 5.0
}


extension Path {
    init(curving points: [CGPoint]) {
        self = Path { path in
            guard let firstPoint = points.first else { return }

            path.move(to: firstPoint)
            var previous = firstPoint

            for point in points.dropFirst() {
                let middle = CGPoint(x: (point.x + previous.x) / 2, y: (point.y + previous.y) / 2)
                path.addQuadCurve(to: middle, control: previous)
                previous = point
            }

            path.addLine(to: previous)
        }
    }
}



