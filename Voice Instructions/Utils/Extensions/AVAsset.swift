//
//  AVAsset.swift
//  Voice Instructions
//
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
