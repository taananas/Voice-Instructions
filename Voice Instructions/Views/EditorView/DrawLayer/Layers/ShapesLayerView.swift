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
            ForEach($layerManager.shapes) { shape in
                SingleShapeView(shapeModel: shape) {
                    layerManager.deactivateAllShape()
                }
            }
        }
        .onTapGesture(perform: layerManager.addShape)
    }
}


struct ShapesLayerView_Previews: PreviewProvider {
    static var previews: some View {
        ShapesLayerView()
            .environmentObject(VideoLayerManager())
    }
}



