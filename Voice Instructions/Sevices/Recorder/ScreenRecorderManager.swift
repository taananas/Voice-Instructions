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
        let name = "\(Date().ISO8601Format()).mp4"
        let url = fileManager.temporaryDirectory.appendingPathComponent(name)
        videoURLs.append(url)
        setupAssetWriters(url)
        AVAudioSession.sharedInstance().playAndRecord()
        recorder.isMicrophoneEnabled = true
        recorder.startCapture { (cmSampleBuffer, rpSampleBufferType, err) in
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
        } completionHandler: { error in
            if let error {
                print(error.localizedDescription)
            }else{
                self.isRecord = true
                self.recorderIsActive = true
            }
        }
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
                        await self.createVideo(self.videoURLs, baseSize: videoFrameSize)
                    }
                }
            }
        }else{
            Task {
                await self.createVideo(self.videoURLs, baseSize: videoFrameSize)
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
    
    
    /// Create video
    /// Merge and render videos
    private func createVideo(_ urls: [URL], baseSize: CGSize) async {
        guard !urls.isEmpty else {
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
                    self.videoURLs.append(finishVideoUrl)
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
        let videoSize = try await videoTrack.load(.naturalSize)
        print("videoSize", videoSize)
        print("cropSize", cropSize)
        
        /// Create a mutable video composition configured to apply Core Image filters to each video frame of the specified asset.
        let composition = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
            
            /// Compute scale and corrective aspect ratio
            let scaleX = cropSize.width / videoSize.width
            let scaleY = cropSize.height / videoSize.height
            let rate = max(scaleX, scaleY)
            let width = videoSize.width * rate
            let height = videoSize.height * rate
            let targetSize = CGSize(width: width, height: height)
            
            /// Handle video frame (CIImage)
            let outputImage = request.sourceImage
            
            /// Define your crop rect here
            /// I would like to crop video from it's center
            let cropRect = CGRect(
                x: (targetSize.width - cropSize.width) / 2,
                y: (targetSize.height - cropSize.height) / 2,
                width: cropSize.width,
                height: cropSize.height
            )
            
            /// Add the .sourceImage (a CIImage) from the request to the filter.
            cropFilter.setValue(outputImage, forKey: kCIInputImageKey)
            /// Specify cropping rectangle with converting it to CIVector
            cropFilter.setValue(CIVector(cgRect: cropRect), forKey: "inputRectangle")
            
            /// Move the cropped image to the origin of the video frame. When you resize the frame (step 4) it will resize from the origin.
            let imageAtOrigin = cropFilter.outputImage!.transformed(
                by: CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y)
            )
            
            request.finish(with: imageAtOrigin, context: context)
        })
        
        /// Update composition render size
        composition.renderSize = cropSize
        
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
                /// Remove old video url
                fileManager.removeFileIfExists(for: url)
                return exportUrl
            }
        }else if let error = exporter?.error{
            throw error
        }
        
        return nil
    }


//    /// Crop video size
//    func cropVideo( _ outputFileUrl: URL) async {
//
//        let videoAsset: AVAsset = AVAsset(url: outputFileUrl)
//
//        do{
//            guard let clipVideoTrack = try await videoAsset.loadTracks(withMediaType: .video).first else {return}
//            let naturalSize = try await clipVideoTrack.load(.naturalSize)
//            let croppedSize = CGSize(width: naturalSize.width - 200, height: naturalSize.height - 400)
//            let duration = try await videoAsset.load(.duration)
//
//            let videoComposition = AVMutableVideoComposition()
//            videoComposition.renderSize = croppedSize
//            videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
//
//            let transformer = AVMutableVideoCompositionLayerInstruction( assetTrack: clipVideoTrack)
//
//            let t1 = CGAffineTransform(translationX: -200, y: -100)
//            let t2 = CGAffineTransform(scaleX: 1.0, y: 1.0)
//            transformer.setTransform(t1.concatenating(t2), at: CMTime.zero)
//            let instruction = AVMutableVideoCompositionInstruction()
//
//            instruction.timeRange = CMTimeRangeMake(start: .zero, duration: duration)
//
//            instruction.layerInstructions = [transformer]
//            videoComposition.instructions = [instruction]
//
//            // Export
//            let exporter = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)!
//            let croppedOutputFileUrl = URL.documentsDirectory.appending(path: "recordFinished.mp4")
//            FileManager.default.removeFileIfExists(for: croppedOutputFileUrl)
//            exporter.videoComposition = videoComposition
//            exporter.outputURL = croppedOutputFileUrl
//            exporter.outputFileType = .mp4
//
//            await exporter.export()
//
//            if exporter.status == .completed {
//                self.finalURl.send(croppedOutputFileUrl)
//                FileManager.default.removeFileIfExists(for: outputFileUrl)
//            }else if let error = exporter.error{
//                print(error.localizedDescription)
//            }
//
//        }catch{
//            print(error.localizedDescription)
//        }
//    }
    
    
}
