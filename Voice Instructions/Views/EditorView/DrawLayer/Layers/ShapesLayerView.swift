//
//  ShapesLayerView.swift
//  Voice Instructions
//
//

import SwiftUI

struct ShapesLayerView: View {
    @ObservedObject var playerManager: VideoPlayerManager
    @EnvironmentObject var layerManager: VideoLayerManager
    var body: some View {
        ZStack{
            Color.white.opacity(0.0001)
            
            /// shapes
            ForEach($layerManager.shapes) { shape in
                
                if shape.wrappedValue.isShapeType{
                    
                    SingleShapeView(shapeModel: shape,
                                    onSelected:  layerManager.deactivateAllObjects,
                                    onDelete: layerManager.removeShape)
                }else{
                    SingleLineShape(shape: shape,
                                    onSelected:  layerManager.deactivateAllObjects,
                                    onDelete: layerManager.removeShape)
                }
            }
            
            
            /// freeLines
            ForEach(layerManager.strokes){ stroke in
                Path(curving: stroke.points)
                    .stroke(style: .init(lineWidth: stroke.width, lineCap: .round, lineJoin: .round))
                    .foregroundColor(stroke.color)
            }
            
            
            ForEach($layerManager.timers) { timer in
                TimerView(currentTime: playerManager.currentTime, timer: timer, onSelected: layerManager.deactivateAllObjects, onRemove: layerManager.removeTimer)
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
                .onEnded{ value in
                    if layerManager.selectedTool == .timer{
                        layerManager.addTimer(value: value, activateTime: playerManager.currentTime)
                    }
                }
        )
    }
}


struct ShapesLayerView_Previews: PreviewProvider {
    static var previews: some View {
        ShapesLayerView(playerManager: VideoPlayerManager())
            .environmentObject(VideoLayerManager())
    }
}



