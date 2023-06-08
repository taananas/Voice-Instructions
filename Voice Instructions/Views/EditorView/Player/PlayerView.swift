//
//  PlayerView.swift
//  Voice Instructions
//
//

import SwiftUI
import AVKit

struct PlayerView: View {
    var player: AVPlayer
    var body: some View {
       PlayerRepresentable(player: player)
            .ignoresSafeArea()
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView(player: AVPlayer())
    }
}

