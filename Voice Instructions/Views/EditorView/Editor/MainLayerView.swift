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
            ZStack{
                PlayerRepresentable(player: playerManager.videoPlayer)
                DrawVideoLayer(layerSize: layerSize)
                    .environmentObject(layerManager)
            }
            .mask {
                Rectangle()
                    .frame(width: layerSize.width, height: layerSize.height)
                    .blendMode(.destinationOver)
            }
            .onAppear{
                setSize(proxy)
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
    
    private func setSize(_ proxy: GeometryProxy){
        let screenSize = proxy.size
        guard let videoSize = playerManager.video?.originalSize else {return}

        let widthScale = screenSize.width / videoSize.width
        let heightScale = screenSize.height / videoSize.height
        let scaleFactor = min(widthScale, heightScale)

        let scaledWidth = videoSize.width * scaleFactor
        let scaledHeight = videoSize.height * scaleFactor

        layerSize = .init(width: scaledWidth, height: scaledHeight)

    }
}
