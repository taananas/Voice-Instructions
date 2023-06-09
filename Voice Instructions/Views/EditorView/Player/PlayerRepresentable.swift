//
//  PlayerRepresentable.swift
//  Voice Instructions
//
//

import SwiftUI
import AVKit

struct PlayerRepresentable: UIViewControllerRepresentable {
    
    var player: AVPlayer
    
    typealias UIViewControllerType = AVPlayerViewController
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let view = AVPlayerViewController()
        view.player = player
        view.showsPlaybackControls = false
        view.videoGravity = .resizeAspect
        view.allowsVideoFrameAnalysis = false
        return view
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
   
}
