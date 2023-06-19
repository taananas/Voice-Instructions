//
//  DrawVideoLayer.swift
//  Voice Instructions
//
//

import SwiftUI

struct DrawVideoLayer: View {
    @EnvironmentObject var layerManager: VideoLayerManager
    var layerSize: CGSize = .zero
    var body: some View {
        ShapesLayerView()
            .frame(width: layerSize.width, height: layerSize.height)
            .disabled(!layerManager.isActiveTool)
    }
}

struct DrawVideoLayer_Previews: PreviewProvider {
    static var previews: some View {
        DrawVideoLayer(layerSize: .init(width: 400, height: 400))
            .environmentObject(VideoLayerManager())
    }
}

extension DrawVideoLayer{
    private var lineIndex: Double{
        layerManager.selectedTool == .line ? 1 : -1
    }
}

