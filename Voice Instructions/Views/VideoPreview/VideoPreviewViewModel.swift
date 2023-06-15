//
//  VideoPreviewViewModel.swift
//  Voice Instructions
//
//

import Foundation
import SwiftUI
import AVKit
import Photos


class VideoPreviewViewModel: ObservableObject{
    
    @Published var video: Video?
    @Published private(set) var thumbnailsImages = [ThumbnailImage]()
    @Published var showLoader: Bool = false
   
    
    @MainActor
    func setVideo(url: URL, size: CGSize) async -> Video{
        let video = await Video(url: url)
        self.video = video
        setThumbnailImages(size, video: video)
        return video
    }
    
    
    /// Save
    /// Create new crop video
    /// Save video in PhotoLibrary
    func save(_ range: ClosedRange<Double>) async {
        guard let video, !showLoader else {return}
        DispatchQueue.main.async {
            self.showLoader = true
        }
        
        let exportSession = await cropTimeVideo(from: video.fullPath, range: range)
        
        if let url = exportSession.outputURL, exportSession.status == .completed{
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) {[weak self] saved, error in
                guard let self = self else {return}
                if saved {
                    DispatchQueue.main.async {
                        self.showLoader = false
                    }
                }
            }
        }
    }
}

/// Thumbnail image logic
extension VideoPreviewViewModel{
    
    /// Create and set thumbnail images
    /// Size - bounds size from geometry reader
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

extension VideoPreviewViewModel{
    
    
    /// Crop video time for range
    func cropTimeVideo(from url: URL, range: ClosedRange<Double>) async -> AVAssetExportSession{
        
        let asset = AVAsset(url: url)
        
        let outputURL = URL.documentsDirectory.appending(path: "\(UUID().uuidString).mp4")
        FileManager.default.removeFileIfExists(for: outputURL)
        
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        let startTime = CMTime(seconds: range.lowerBound, preferredTimescale: 1000)
        let endTime = CMTime(seconds: range.upperBound, preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        exportSession.timeRange = timeRange
        
        await exportSession.export()
        
        return exportSession
    
    }
}
    

