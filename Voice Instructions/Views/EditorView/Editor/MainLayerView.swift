//
//  MainLayerView.swift
//  Voice Instructions
//
//

import SwiftUI

struct MainLayerView: View {
    @ObservedObject var playerManager: VideoPlayerManager
    @EnvironmentObject var layerManager: VideoLayerManager
    @State private var layerSize: CGSize = .zero
    var body: some View {
    
        GeometryReader { proxy in
            let newLayerSize = getSize(proxy)
            ZStack{
                PlayerRepresentable(size: $layerSize, player: playerManager.videoPlayer)
                DrawVideoLayer(playerManager: playerManager, layerSize: newLayerSize)
                    .environmentObject(layerManager)
            }
            .maskOptionally(isActive: layerSize != .zero) {
                Rectangle()
                    .frame(size: newLayerSize)
                    .blendMode(.destinationOver)
            }
        }
        .ignoresSafeArea()
    }
}

struct MainLayerView_Previews: PreviewProvider {
    static var previews: some View {
        MainLayerView(playerManager: VideoPlayerManager())
            .environmentObject(VideoLayerManager())
    }
}

extension MainLayerView{
    
    
    private func getSize(_ proxy: GeometryProxy) -> CGSize{
        .init(
            width: layerSize.width > proxy.size.width ? proxy.size.width : layerSize.width,
            height: layerSize.height > proxy.size.height ? proxy.size.height : layerSize.height
        )
    }
}

