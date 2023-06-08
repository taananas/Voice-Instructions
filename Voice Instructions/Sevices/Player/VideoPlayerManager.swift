//
//  VideoPlayerManager.swift
//  Voice Instructions
//
//

import Foundation
import Combine
import AVKit
import PhotosUI
import SwiftUI


/// A class for video management
final class VideoPlayerManager: ObservableObject{
    
    @Published var selectedItem: PhotosPickerItem?
    @Published var currentTime: Double = .zero
    @Published var video: Video?
    @Published private(set) var loadState: LoadState = .unknown
    @Published private(set) var isPlaying: Bool = false
    
    private(set) var videoPlayer = AVPlayer()
    
    private var rate: Float = 1
    private var cancelBag = CancelBag()
    private var timeObserver: Any?
    private var currentDurationRange: ClosedRange<Double>?
    private var isSeekInProgress: Bool = false
    private let videoStorageService = VideoStorageService.shared
    
    deinit {
        removeTimeObserver()
    }
    
    init(){
        loadVideo()
    }

    /// Scrubbing state for seek video time
    var scrubState: PlayerScrubState = .reset {
        didSet {
            switch scrubState {
            case .scrubEnded(let seekTime):
                pause()
                seek(seekTime)
            default : break
            }
        }
    }
    
    /// Play or pause video
    func action(){
        guard let video else {return}
        self.currentDurationRange = video.rangeDuration
        if isPlaying{
            pause()
        }else{
            play(rate)
        }
    }
    
    /// Observing the change timeControlStatus
    private func startControlStatusSubscriptions(){
        videoPlayer.publisher(for: \.timeControlStatus)
            .sink { [weak self] status in
                guard let self = self else {return}
                switch status {
                case .playing:
                    self.startTimer()
                    self.isPlaying = true
                case .paused:
                    self.isPlaying = false
                case .waitingToPlayAtSpecifiedRate:
                    break
                @unknown default:
                    break
                }
            }
            .store(in: cancelBag)
    }
    
    
    func pause(){
        if isPlaying{
            videoPlayer.pause()
        }
    }
    
    /// Set video volume
    func setVolume(_ isVideo: Bool, value: Float){
        pause()
        if isVideo{
            videoPlayer.volume = value
        }
    }

    /// Play for rate and durationRange
    private func play(_ rate: Float?){
        
        AVAudioSession.sharedInstance().configurePlaybackSession()
        
        if let currentDurationRange{
            if currentTime >= currentDurationRange.upperBound{
                seek(currentDurationRange.lowerBound)
            }else{
                seek(videoPlayer.currentTime().seconds)
            }
        }
        videoPlayer.play()
        
        if let rate{
            self.rate = rate
            videoPlayer.rate = rate
        }
        
        if let currentDurationRange, videoPlayer.currentItem?.duration.seconds ?? 0 >= currentDurationRange.upperBound{
            NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: videoPlayer.currentItem, queue: .main) { _ in
                self.playerDidFinishPlaying()
            }
        }
    }
     
    /// Seek video time
     func seek(_ seconds: Double){
         if isSeekInProgress{return}
         isSeekInProgress = true
         videoPlayer.seek(to: CMTimeMakeWithSeconds(seconds, preferredTimescale: 600), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) {[weak self] isFinished in
             guard let self = self else {return}
             if isFinished{
                 self.isSeekInProgress = false
             }else{
                 self.seek(seconds)
             }
         }
    }
    
    func setRateAndPlay(_ rate: Float){
        videoPlayer.pause()
        play(rate)
    }
    
    /// Start video timer
    private func startTimer() {
        
        let interval = CMTimeMake(value: 1, timescale: 10)
        timeObserver = videoPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            if self.isPlaying{
                let time = time.seconds
                
                if let currentDurationRange = self.currentDurationRange, time >= currentDurationRange.upperBound{
                    self.pause()
                }

                switch self.scrubState {
                case .reset:
                    self.currentTime = time
                case .scrubEnded:
                    self.scrubState = .reset
                case .scrubStarted:
                    break
                }
            }
        }
    }
    
    /// Did finish action seek to zero
    private func playerDidFinishPlaying() {
        self.videoPlayer.seek(to: .zero)
    }
    
    /// Remove all time observers
    private func removeTimeObserver(){
        if let timeObserver = timeObserver {
            videoPlayer.removeTimeObserver(timeObserver)
        }
    }
    
}

extension VideoPlayerManager{
    
    
    /// Load item from PhotosPicker
    @MainActor
    func loadVideoItem(_ selectedItem: PhotosPickerItem?) async{
        do {
            loadState = .loading
            if let video = try await selectedItem?.loadTransferable(type: VideoItem.self) {
                self.pause()
                self.videoPlayer = AVPlayer(url: video.url)
                let duration = try? await videoPlayer.currentItem?.asset.load(.duration).seconds
                self.video = .init(url: video.url, originalDuration: duration ?? 1)
                self.startControlStatusSubscriptions()
                print("AVPlayer set url:", video.url.absoluteString)
                self.save()
                loadState = .loaded
                self.action()
            } else {
                loadState = .failed
            }
        } catch {
            print(error.localizedDescription)
            loadState = .failed
        }
    }
}

extension VideoPlayerManager{
    
    enum LoadState: Int {
        case unknown, loading, loaded, failed
    }

    enum PlayerScrubState{
        case reset
        case scrubStarted
        case scrubEnded(Double)
    }
}






extension VideoPlayerManager{
    
    /// load storage video object
    private func loadVideo(){
        self.video = videoStorageService.load()
        if let video{
            self.videoPlayer = AVPlayer(url: video.url)
            self.startControlStatusSubscriptions()
            self.loadState = .loaded
        }
        
    }
    
    private func save(){
        guard let video else {return}
        videoStorageService.save(video)
    }
    
    ///remove copy video and storage video object
    func removeVideo(){
        if let video{
            FileManager.default.removeFileExists(for: video.url)
            videoStorageService.remove()
            removeTimeObserver()
            self.videoPlayer = .init()
            self.loadState = .unknown
        }
    }
}
