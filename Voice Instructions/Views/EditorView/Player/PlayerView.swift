//
//  PlayerView.swift
//  Voice Instructions
//
//  Created by Bogdan Zykov on 08.06.2023.
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

