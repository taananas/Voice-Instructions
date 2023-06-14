//
//  PlayerRepresentable.swift
//  Voice Instructions
//
//

import SwiftUI
import AVKit

struct PlayerRepresentable: UIViewControllerRepresentable {
    
    var player: AVPlayer
    var videoSize: CGSize?
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let view = AVPlayerViewController()
        view.player = player
        view.showsPlaybackControls = false

        view.allowsVideoFrameAnalysis = false
    
        
        guard let videoSize else {
            view.videoGravity = .resizeAspect
            return view
        }
        
        if videoSize.width > videoSize.height{
            view.videoGravity = .resizeAspect
        }else{
            view.videoGravity = .resizeAspectFill
        }
        
        return view
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    }
   
}
