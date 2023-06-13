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
    @Published private(set) var isRecord: Bool = false
    private var finalURl = CurrentValueSubject<URL?, Never>(nil)
    private(set) var videoURLs = [URL]()
    
    private let recorder = RPScreenRecorder.shared()
    private var assetWriter: AVAssetWriter!
    private var videoInput: AVAssetWriterInput!
    private var audioMicInput: AVAssetWriterInput!
    private var cancelBag = CancelBag()
    
    
    init(){
        startFinishedSubs()
    }
    
    func startRecoding(){
        let name = "\(Date().ISO8601Format()).mp4"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
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
    
    func removeAll(){
        isRecord = false
        recorderIsActive = false
        videoURLs = []
        if let finalURl = finalURl.value{
            FileManager.default.removeFileExists(for: finalURl)
        }
    }
    
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
    
    func stop(){
        
        if recorder.isRecording{
            recorder.stopCapture { (error) in
                
                if let error{
                    print(error.localizedDescription)
                    self.isRecord = false
                    return
                }
                
                guard let videoInput = self.videoInput,
                      let audioMicInput = self.audioMicInput,
                      let assetWriter = self.assetWriter else {
                    self.isRecord = false
                    return
                }
                
                videoInput.markAsFinished()
                audioMicInput.markAsFinished()
                assetWriter.finishWriting {
                    
                    DispatchQueue.main.async {
                        self.isRecord = false
                    }
                    
                    Task {
                        await self.createVideo(self.videoURLs)
                    }
                }
            }
        }else{
            Task {
                await self.createVideo(self.videoURLs)
            }
        }
    }
    
    //    private func showShareSheet(data: Any){
    //        UIActivityViewController(activityItems: [data], applicationActivities: nil).presentInKeyWindow()
    //    }
    
    
    private func startFinishedSubs(){
        finalURl
            .receive(on: RunLoop.main)
            .sink { url in
                guard let url else {return}
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { (saved, error) in
                    
                    if let error = error {
                        print("PHAssetChangeRequest Video Error: \(error.localizedDescription)")
                        return
                    }
                    if saved {
                        print("Saved")
                        // ... show success message
                    }
                }
            }
            .store(in: cancelBag)
    }
    
    private func createVideo(_ urls: [URL]) async {
        guard !urls.isEmpty else {
            return
        }
        let assets = urls.map({AVAsset(url: $0)})
        
        let composition = AVMutableComposition()
        
        print(urls)
        
        do{
            try await mergeVideos(to: composition, from: assets)
            
            ///Remove all cash videos
            urls.forEach { url in
                FileManager.default.removeFileExists(for: url)
            }
            self.videoURLs.removeAll(keepingCapacity: false)
            
        }catch{
            print(error.localizedDescription)
        }
        
        
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        let exportUrl =  URL.documentsDirectory.appending(path: "record.mp4")

        FileManager.default.removeFileExists(for: exportUrl)
        
        exporter?.outputURL = exportUrl
        exporter?.outputFileType = .mp4
        
        await exporter?.export()
        
        if exporter?.status == .completed {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: exportUrl.path) {
                self.finalURl.send(exportUrl)
            }
        }
    }
    
}


//MARK: - Helpers
extension ScreenRecorderManager{
    
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
            AVVideoWidthKey: UIScreen.main.nativeBounds.width / 1.1,
            AVVideoHeightKey: UIScreen.main.nativeBounds.height / 1.1,
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
    
    private func mergeVideos(to composition: AVMutableComposition,
                                          from assets: [AVAsset]) async throws{
        
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var lastTime: CMTime = .zero
        
        for asset in assets {
            
            let videoTracks =  try await asset.loadTracks(withMediaType: .video)
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            
            let duration = try await asset.load(.duration)
            let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
            
            
            if !audioTracks.isEmpty{
                let audioTrack = audioTracks.first!
                try compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: lastTime)
                let auduoPreferredTransform = try await audioTrack.load(.preferredTransform)
                compositionAudioTrack?.preferredTransform = auduoPreferredTransform
            }

            let videoTrack = videoTracks.first!
            try compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: lastTime)
            let videoPreferredTransform = try await videoTrack.load(.preferredTransform)
            compositionVideoTrack?.preferredTransform = videoPreferredTransform
            
            lastTime = CMTimeAdd(lastTime, duration)
        }
    }
    
}
