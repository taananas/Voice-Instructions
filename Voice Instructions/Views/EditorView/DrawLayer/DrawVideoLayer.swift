//
//  DrawVideoLayer.swift
//  Voice Instructions
//
//

import SwiftUI

struct DrawVideoLayer: View {
    @ObservedObject var playerManager: VideoPlayerManager
    @State private var layerSize: CGSize = .zero
    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(Color.red.opacity(0.1))
                .frame(width: layerSize.width, height: layerSize.height)
                .position(x: proxy.frame(in: .local).midX, y: proxy.frame(in: .local).midY - 6)
                .onAppear{
                    setSize(proxy)
                }
        }
    }
}

struct DrawVideoLayer_Previews: PreviewProvider {
    static var previews: some View {
        DrawVideoLayer(playerManager: VideoPlayerManager())
    }
}

extension DrawVideoLayer{
    
    
    private func setSize(_ proxy: GeometryProxy){
        
        let screenSize = proxy.size
        
        guard
            let presentationSize = playerManager.videoPlayer.currentItem?.presentationSize else {return}
        
        let widthScale = screenSize.width / presentationSize.width
        let heightScale = screenSize.height / presentationSize.height
        let scaleFactor = min(widthScale, heightScale)
        
        let scaledWidth = presentationSize.width * scaleFactor
        let scaledHeight = presentationSize.height * scaleFactor

        
        layerSize = .init(width: scaledWidth, height: scaledHeight)
        
    }
    
}
