//
//  PlayerRepresentable.swift
//  Voice Instructions
//
//

import SwiftUI
import AVKit

struct PlayerRepresentable: UIViewControllerRepresentable {
    
    var player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let view = AVPlayerViewController()
        view.player = player
        view.showsPlaybackControls = false

        view.allowsVideoFrameAnalysis = false
        
        view.videoGravity = .resizeAspect
        
        return view
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    }
   
}
