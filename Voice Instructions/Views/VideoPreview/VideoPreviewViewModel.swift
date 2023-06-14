//
//  VideoPreviewViewModel.swift
//  Voice Instructions
//
//  Created by Bogdan Zykov on 14.06.2023.
//

import Foundation
import SwiftUI
import AVKit


class VideoPreviewViewModel: ObservableObject{
    
    @Published var video: Video?
    @Published private(set) var thumbnailsImages = [ThumbnailImage]()
    
   
    
    @MainActor
    func setVideo(url: URL, size: CGSize) async -> Video{
        let video = await Video(url: url)
        self.video = video
        setThumbnailImages(size, video: video)
        return video
    }
    
}

/// Thumbnail image logic
extension VideoPreviewViewModel{
    
    
    private func setThumbnailImages(_ size: CGSize, video: Video){
        
        let imagesCount = thumbnailCount(size)
        let asset = AVAsset(url: video.fullPath)
        var offset: Float64 = 0
        for i in 0..<imagesCount{
            let thumbnailImage = ThumbnailImage(image: asset.getImage(Int(offset)))
            offset = Double(i) * (video.originalDuration / Double(imagesCount))
            thumbnailsImages.append(thumbnailImage)
        }
    }
    
    private func thumbnailCount(_ size: CGSize) -> Int {
        let horizontalPadding: CGFloat = 32
        let num = Double(size.width - horizontalPadding) / Double(70 / 1.5)
        
        return Int(ceil(num))
    }
    
    struct ThumbnailImage: Identifiable{
        var id: UUID = UUID()
        var image: UIImage?
        
        
        init(image: UIImage? = nil) {
            self.image = image?.resize(to: .init(width: 150, height: 150))
        }
    }
}
