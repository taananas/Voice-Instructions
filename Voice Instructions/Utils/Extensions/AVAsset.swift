//
//  AVAsset.swift
//  Voice Instructions
//
//  Created by Bogdan Zykov on 09.06.2023.
//

import AVFoundation

extension AVAsset{
    
    func naturalSize() async -> CGSize? {
        guard let tracks = try? await loadTracks(withMediaType: .video) else { return nil }
        guard let track = tracks.first else { return nil }
        guard let size = try? await track.load(.naturalSize) else { return nil }
        return size
    }
    
}
