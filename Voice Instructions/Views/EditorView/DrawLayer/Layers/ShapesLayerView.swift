//
//  ShapesLayerView.swift
//  Voice Instructions
//
//

import SwiftUI

struct ShapesLayerView: View {
    @EnvironmentObject var layerManager: VideoLayerManager
    var body: some View {
        ZStack{
            Color.white.opacity(0.0001)
            
            /// shapes
            ForEach($layerManager.shapes) { shape in
                
                if shape.wrappedValue.isShapeType{
                    SingleShapeView(shapeModel: shape, onSelected:  layerManager.deactivateAllShape)
                }else{
                    SingleLineShape(shape: shape, onSelected:  layerManager.deactivateAllShape)
                }
            }
            
            
            /// freeLines
            ForEach(layerManager.strokes.indices, id: \.self){index in
                Path(curving: layerManager.strokes[index].points)
                    .stroke(style: .init(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .foregroundColor(layerManager.strokes[index].color)
            }
            
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if layerManager.selectedTool == .polyLine{
                        layerManager.addLine(value: value)
                    }else{
                        layerManager.addShape(value: value)
                    }
                }
        )
        
    }
}


struct ShapesLayerView_Previews: PreviewProvider {
    static var previews: some View {
        ShapesLayerView()
            .environmentObject(VideoLayerManager())
    }
}



