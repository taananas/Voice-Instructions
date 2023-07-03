//
//  ScreenRecorderManager.swift
//  Voice Instructions
//
//

import AVFoundation
import ReplayKit
import Photos
import Combine


class ScreenRecorderManager: ObservableObject{
    
    @Published var recorderIsActive: Bool = false
    @Published var showPreview: Bool = false
    @Published private(set) var isRecord: Bool = false
    @Published private(set) var showLoader: Bool = false
    private(set) var finalVideo = CurrentValueSubject<Video?, Never>(nil)
    private(set) var videoURLs = [URL]()
    private var videoCounter: Int = 0
    
    private let recorder = RPScreenRecorder.shared()
    private var assetWriter: AVAssetWriter!
    private var videoInput: AVAssetWriterInput!
    private var audioMicInput: AVAssetWriterInput!
    private var cancelBag = CancelBag()
    private let fileManager = FileManager.default
    
    
    init(){
        startCreatorSubs()
    }
    
    /// start record session, initializing the record alert
    /// setup AssetWriters
    /// save audio and video buffer
    func startRecoding(){
        AVAudioSession.sharedInstance().playAndRecord()
        recorder.isMicrophoneEnabled = true
        recorder.startCapture { [weak self] (cmSampleBuffer, rpSampleBufferType, err) in
            guard let self = self else {return}
            if let err = err {
                print(err.localizedDescription)
                return
            }
            if CMSampleBufferDataIsReady(cmSampleBuffer) {
                DispatchQueue.main.async {
                    
                    switch rpSampleBufferType {
                    case .video:
                        
                        if self.assetWriter?.status == AVAssetWriter.Status.unknown {
                            print("Started writing")
                            self.assetWriter?.startWriting()
                            self.assetWriter?.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(cmSampleBuffer))
                        }
                        
                        if self.assetWriter.status == AVAssetWriter.Status.failed {
                            print("StartCapture Error Occurred, Status = \(self.assetWriter.status.rawValue), \(self.assetWriter.error!.localizedDescription) \(self.assetWriter.error.debugDescription)")
                            return
                        }
                        
                        if self.assetWriter.status == AVAssetWriter.Status.writing {
                            if self.videoInput.isReadyForMoreMediaData {
                                print("Writing a sample")
                                if self.videoInput.append(cmSampleBuffer) == false {
                                    print("problem writing video")
                                }
                            }
                        }
                        
                    case .audioMic:
                        if self.audioMicInput.isReadyForMoreMediaData {
                            print("audioMic data added")
                            self.audioMicInput.append(cmSampleBuffer)
                        }
                        
                    default: break
                    }
                }
            }
        } completionHandler: { [weak self] error in
            guard let self = self else {return}
            if let error {
                print(error.localizedDescription)
            }else{
                self.createFileAndSetupAssetWriters()
                self.isRecord = true
                self.recorderIsActive = true
            }
        }
    }
    
    private func createFileAndSetupAssetWriters(){
        let name = "\(Date().ISO8601Format()).mp4"
        let url = fileManager.temporaryDirectory.appendingPathComponent(name)
        videoURLs.append(url)
        setupAssetWriters(url)
    }
    
    ///remove all video and reset state
    func removeAll(){
        isRecord = false
        recorderIsActive = false
        videoURLs.forEach { url in
            fileManager.removeFileIfExists(for: url)
        }
        if let finalURl = finalVideo.value?.fullPath{
            fileManager.removeFileIfExists(for: finalURl)
        }
        videoURLs = []
        resetVideoCounter()
    }
    
    /// Pause
    /// stop capture and finish writing
    func pause(){
        recorder.stopCapture { error in
            self.videoInput.markAsFinished()
            self.audioMicInput.markAsFinished()
            self.assetWriter.finishWriting {
                DispatchQueue.main.async {
                    self.isRecord = false
                }
            }
        }
    }
    
    /// Stop
    /// If we record stop and create video otherwise we create a video
    func stop(videoFrameSize: CGSize){
        showLoader = true
        if recorder.isRecording{
            recorder.stopCapture { (error) in
                if let error{
                    print(error.localizedDescription)
                    self.isRecord = false
                    self.showLoader = false
                    return
                }
                guard let videoInput = self.videoInput,
                      let assetWriter = self.assetWriter else {
                    self.isRecord = false
                    self.showLoader = false
                    return
                }
                
                videoInput.markAsFinished()
                
                if let audioMicInput = self.audioMicInput {
                    audioMicInput.markAsFinished()
                }
               
                assetWriter.finishWriting {
                    
                    DispatchQueue.main.async {
                        self.isRecord = false
                    }
                    
                    Task {
                        await self.createVideoIfNeeded(self.videoURLs, baseSize: videoFrameSize)
                    }
                }
            }
        }else{
            Task {
                await self.createVideoIfNeeded(self.videoURLs, baseSize: videoFrameSize)
            }
        }
    }
    
    /// Subscription to create a video
    private func startCreatorSubs(){
        finalVideo
            .receive(on: RunLoop.main)
            .sink { video in
                guard video != nil else {return}
                self.showLoader = false
                self.showPreview = true
            }
            .store(in: cancelBag)
    }
    
    private var isNotAddedNew: Bool{
        finalVideo.value != nil && videoCounter == videoURLs.count
    }
    
    
    /// Create video
    /// Merge and render videos
    private func createVideoIfNeeded(_ urls: [URL], baseSize: CGSize) async {
        guard !urls.isEmpty else {
            return
        }
        
        if isNotAddedNew{
            finalVideo.send(finalVideo.value)
            return
        }
        
        let composition = AVMutableComposition()
        
        print("Merged video urls:", urls)
        
        do{
            try await mergeVideos(to: composition, from: urls, audioEnabled: recorder.isMicrophoneEnabled)
            
            ///Remove all cash videos
            urls.forEach { url in
                fileManager.removeFileIfExists(for: url)
            }
            self.videoURLs.removeAll(keepingCapacity: false)
            
        }catch{
            print(error.localizedDescription)
        }
        
        
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        let exportUrl =  URL.documentsDirectory.appending(path: "record.mp4")
        fileManager.removeFileIfExists(for: exportUrl)
        
        exporter?.outputURL = exportUrl
        exporter?.outputFileType = .mp4
        exporter?.shouldOptimizeForNetworkUse = false

        await exporter?.export()

        if exporter?.status == .completed {
            
            if fileManager.fileExists(atPath: exportUrl.path) {
                /// CropVideo
                let finishVideoUrl = try? await cropVideoWithGivenSize(
                    url: exportUrl,
                    baseSize:
                            .init(width: baseSize.width * UIScreen.main.scale, height: baseSize.height * UIScreen.main.scale))
                
                if let finishVideoUrl{
                    ///create video
                    self.createVideo(finishVideoUrl)
                    /// append original non croped video
                    self.videoURLs.append(exportUrl)
                    
                    self.videoCounter = videoURLs.count
                }
            }
        }else if let error = exporter?.error{
            print(error.localizedDescription)
        }
    }
    
    
    private func createVideo(_ url: URL){
        Task{
            let video = await Video(url: url)
            finalVideo.send(video)
        }
    }
    
    func resetVideoCounter(){
        videoCounter = 0
    }
}


//MARK: - Helpers
extension ScreenRecorderManager{
    
    
    /// Setup AVAssetWriter
    /// Setup video and audio settings
    /// High quality video and audio
    private func setupAssetWriters(_ url: URL){
        do {
            try assetWriter = AVAssetWriter(outputURL: url, fileType: .mp4)
        } catch {
            print(error.localizedDescription)
        }
        
        let videoCodecType = AVVideoCodecType.h264
        let bitsPerSecond: Int = 25_000_000
        let profileLevel = AVVideoProfileLevelH264HighAutoLevel
        
        let compression: [String : Any] = [
            AVVideoAverageBitRateKey: bitsPerSecond,
            AVVideoProfileLevelKey: profileLevel,
            AVVideoExpectedSourceFrameRateKey: 60
        ]
        
        let videoOutputSettings: [String: Any] = [
            AVVideoCodecKey: videoCodecType,
            AVVideoWidthKey: UIScreen.main.nativeBounds.width,
            AVVideoHeightKey: UIScreen.main.nativeBounds.height,
            AVVideoCompressionPropertiesKey: compression,
        ]
        
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
        videoInput.expectsMediaDataInRealTime = true
        
        if assetWriter.canAdd(videoInput) {
            assetWriter.add(videoInput)
        }
        
        let audioSettings: [String: Any] = [
            AVFormatIDKey : kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey : 2,
            AVSampleRateKey : 44100.0,
            AVEncoderBitRateKey: 192000
        ]
        
        audioMicInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioMicInput.expectsMediaDataInRealTime = true
        if assetWriter.canAdd(audioMicInput) {
            assetWriter.add(audioMicInput)
        }
    }
    
    /// Merge videos
    /// Combining multiple videos for a composition
    /// audioEnabled:  Turning on the audio track
    private func mergeVideos(to composition: AVMutableComposition,
                             from urls: [URL], audioEnabled: Bool) async throws{
        
        let assets = urls.map({AVAsset(url: $0)})
        
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let compositionAudioTrack: AVMutableCompositionTrack? = audioEnabled ? composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) : nil
        
        var lastTime: CMTime = .zero
        
        for asset in assets {
            
            let videoTracks = try await asset.loadTracks(withMediaType: .video)
            let audioTracks = try? await asset.loadTracks(withMediaType: .audio)
            
            let duration = try await asset.load(.duration)
           
            let timeRange = CMTimeRangeMake(start: .zero, duration: duration)
            
            
            print("duration:", duration.seconds, "lastTime:", lastTime.seconds)
            
            if let audioTracks, !audioTracks.isEmpty, let audioTrack = audioTracks.first,
               let compositionAudioTrack {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: lastTime)
                let audioPreferredTransform = try await audioTrack.load(.preferredTransform)
                compositionAudioTrack.preferredTransform = audioPreferredTransform
            }
            
            guard let videoTrack = videoTracks.first else {return}
            try compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: lastTime)
            let videoPreferredTransform = try await videoTrack.load(.preferredTransform)
            compositionVideoTrack?.preferredTransform = videoPreferredTransform
            
            lastTime = CMTimeAdd(lastTime, duration)
        }

        print("TotalTime:", lastTime.seconds)
    }
    
    

    /// Calculate video frame (center it)
    func cropVideoWithGivenSize(url: URL, baseSize cropSize: CGSize) async throws -> URL?{
        
        let asset = AVAsset(url: url)
        
        /// Create your context and filter
        /// I'll use metal context and CIFilter
        guard let device = MTLCreateSystemDefaultDevice(),
              let cropFilter = CIFilter(name: "CICrop"),
              let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {return nil}
        
        let context = CIContext(mtlDevice: device, options: [.workingColorSpace : NSNull()])
        
        /// Original video size
        let originalSize = try await videoTrack.load(.naturalSize)
        let duration = try await asset.load(.duration)
        
//
//        // Compute scale and corrective aspect ratio
//        let scaleX = cropSize.width / originalSize.width
//        let scaleY = cropSize.height / originalSize.height
//        let rate = max(scaleX, scaleY)
//        let width = originalSize.width * rate
//        let height = originalSize.height * rate
//        let targetSize = CGSize(width: width, height: height)
        
        /// Define your crop rect here
        /// I would like to crop video from it's center
        let cropRect = CGRect(
            x: (originalSize.width - cropSize.width) / 2,
            y: (originalSize.height - cropSize.height) / 2,
            width: cropSize.width,
            height: cropSize.height
        ).integral

        print("cropSize", cropSize)
        print("Old video size", originalSize)

        
        /// Create a mutable video composition configured to apply Core Image filters to each video frame of the specified asset.
        let composition = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in

            /// Handle video frame (CIImage)
            let outputImage = request.sourceImage

            /// Add the .sourceImage (a CIImage) from the request to the filter.
            cropFilter.setValue(outputImage, forKey: kCIInputImageKey)
            /// Specify cropping rectangle with converting it to CIVector
            cropFilter.setValue(CIVector(cgRect: cropRect), forKey: "inputRectangle")

            /// Move the cropped image to the origin of the video frame. When you resize the frame (step 4) it will resize from the origin.
            let imageAtOrigin = cropFilter.outputImage!
                .transformed(
                    by: CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y)
            )
            request.finish(with: imageAtOrigin, context: context)
        })
        
        /// Update composition render size
        composition.renderSize = cropRect.size
        
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        let exportUrl = URL.documentsDirectory.appending(path: "preview_record.mp4")
        fileManager.removeFileIfExists(for: exportUrl)
        
        exporter?.videoComposition = composition
        exporter?.outputURL = exportUrl
        exporter?.outputFileType = .mp4
        exporter?.shouldOptimizeForNetworkUse = false
        
        await exporter?.export()
        
        if exporter?.status == .completed {
            if fileManager.fileExists(atPath: exportUrl.path) {
                return exportUrl
            }
        }else if let error = exporter?.error{
            throw error
        }
        
        return nil
    }

    

    enum Orientation {
        case up, down, right, left
    }
    
    func orientation(for track: AVAssetTrack) async -> Orientation{
        
        guard let t = try? await track.load(.preferredTransform) else{
            return .down
        }
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) {             // Portrait
            return .up
        } else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0) {      // PortraitUpsideDown
            return .down
        } else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0) {       // LandscapeRight
            return .right
        } else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0) {     // LandscapeLeft
            return .left
        } else {
            return .up
        }
    }
    
    
}

extension Double {
    
     var radians: Double {
         .pi * self / 180
    }
}






//func cropVideoWithGivenSize(url: URL, baseSize cropSize: CGSize) async throws -> URL?{
//
//    let asset = AVAsset(url: url)
//
//    /// Create your context and filter
//    /// I'll use metal context and CIFilter
//    guard let device = MTLCreateSystemDefaultDevice(),
//          let cropFilter = CIFilter(name: "CICrop"),
//          let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {return nil}
//
//    let context = CIContext(mtlDevice: device, options: [.workingColorSpace : NSNull()])
//
//    /// Original video size
//    let originalSize = try await videoTrack.load(.naturalSize)
//    let duration = try await asset.load(.duration)
//
//    // Compute scale and corrective aspect ratio
//    let scaleX = cropSize.width / originalSize.width
//    let scaleY = cropSize.height / originalSize.height
//    let rate = max(scaleX, scaleY)
//    let width = originalSize.width * rate
//    let height = originalSize.height * rate
//    let targetSize = CGSize(width: width, height: height)
//
//
//    print("cropSize", cropSize)
//    print("Old video size", originalSize)
//    //print("New video size", cropRect.size)
//
//        let composition = AVMutableComposition()
//
//        let trackOrientation = await orientation(for: videoTrack)
//        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
//        let videoComposition = AVMutableVideoComposition()
//
//
//        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
//
//
//        var finalTransform: CGAffineTransform = CGAffineTransform.identity
//        let cropRect = CGRect(
//            x: (originalSize.width - cropSize.width) / 2,
//            y: (originalSize.height - cropSize.height) / 2,
//            width: cropSize.width,
//            height: cropSize.height
//        ).integral
//
//        let cropOffX: CGFloat = cropRect.origin.x
//        let cropOffY: CGFloat = cropRect.origin.y
//
//        videoComposition.renderSize = cropRect.size
//
//        switch trackOrientation {
//        case .up:
//            finalTransform = finalTransform
//                .translatedBy(x: originalSize.height - cropOffX, y: 0 - cropOffY)
//                .rotated(by: CGFloat(90.0.radians))
//        case .down:
//            finalTransform = finalTransform
//                .translatedBy(x: 0 - cropOffX, y: originalSize.width - cropOffY)
//                .rotated(by: CGFloat(-90.0.radians))
//        case .right:
//            finalTransform = finalTransform.translatedBy(x: 0 - cropOffX, y: 0 - cropOffY)
//        case .left:
//            finalTransform = finalTransform
//                .translatedBy(x: originalSize.width - cropOffX, y: originalSize.height - cropOffY)
//                .rotated(by: CGFloat(-180.0.radians))
//        }
//
//
//
//        let instruction = AVMutableVideoCompositionInstruction()
//        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
//
//        transformer.setTransform(finalTransform, at: .zero)
//        instruction.layerInstructions = [transformer]
//        videoComposition.instructions = [instruction]
//
//
//
//
//
//    let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
//    let exportUrl = URL.documentsDirectory.appending(path: "preview_record.mp4")
//    fileManager.removeFileIfExists(for: exportUrl)
//
//    exporter?.videoComposition = videoComposition
//    exporter?.outputURL = exportUrl
//    exporter?.outputFileType = .mp4
//    exporter?.shouldOptimizeForNetworkUse = false
//
//    await exporter?.export()
//
//    if exporter?.status == .completed {
//        if fileManager.fileExists(atPath: exportUrl.path) {
//            return exportUrl
//        }
//    }else if let error = exporter?.error{
//        throw error
//    }
//
//    return nil
//}
