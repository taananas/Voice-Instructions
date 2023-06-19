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
                    
                    SingleShapeView(shapeModel: shape,
                                    onSelected:  layerManager.deactivateAllShape,
                                    onDelete: layerManager.removeShape)
                }else{
                    SingleLineShape(shape: shape,
                                    onSelected:  layerManager.deactivateAllShape,
                                    onDelete: layerManager.removeShape)
                }
            }
            
            
            /// freeLines
            ForEach(layerManager.strokes){ stroke in
                Path(curving: stroke.points)
                    .stroke(style: .init(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .foregroundColor(stroke.color)
            }
            
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if layerManager.selectedTool == .polyLine{
                        layerManager.addLine(value: value)
                    }else if layerManager.selectedTool?.isShapeTool ?? false{
                        layerManager.addShape(value: value)
                    }
                }
        )
        .onAppear{
            layerManager.selectedTool = .rectangle
        }
    }
}


struct ShapesLayerView_Previews: PreviewProvider {
    static var previews: some View {
        ShapesLayerView()
            .environmentObject(VideoLayerManager())
    }
}



