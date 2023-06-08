//
//  VideoControlsView.swift
//  Voice Instructions
//
//

import SwiftUI

struct VideoControlsView: View {
    @ObservedObject var playerManager: VideoPlayerManager
    var video: Video
    private let thumbRadius: CGFloat = 30
    @State private var showRatePicker: Bool = false
    @State var selectedRate: EnumRate = .x1
    var body: some View {
        VStack{
            timeSlider
                .padding(.horizontal, 18)
            HStack(spacing: 16) {
                ScrubbingBarView(duration: playerManager.video?.totalDuration ?? 60, time: $playerManager.currentTime, onChangeTime: seek)
                    .padding(.horizontal, 40)
            }
            .padding(.horizontal, 18)
            .overlay {
                HStack{
                    playPauseButton
                    Spacer()
                    rateButton
                }
            }
        }
        
        .vBottom()
        .overlay {
            Group{
                if showRatePicker{
                    ZStack(alignment: .bottomTrailing){
                        Color.black.opacity(0.1)
                            .onTapGesture {
                                showRatePicker.toggle()
                            }
                       ratePicker
                    }
                }
            }
            .animation(.default, value: showRatePicker)
        }
    }
}

struct VideoControlsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack{
            Color.black
            VideoControlsView(playerManager: VideoPlayerManager(), video: .mock)
        }
    }
}

extension VideoControlsView{
    
    
    private var playPauseButton: some View{
        Button {
            playerManager.action()
        } label: {
            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(.white)
        }
        .padding(.horizontal)
    }
    
    private func seek(_ time: Double){
        playerManager.scrubState = .scrubEnded(time)
    }
    
    private var timeSlider: some View{
        
        GeometryReader { proxy in
            CustomSlider(value: Binding(get: {
                playerManager.currentTime
            }, set: { newValue in
                playerManager.currentTime = newValue
                seek(newValue)
            }),
                         in: video.rangeDuration,
                         step: 0.003,
                         onEditingChanged: { started in
                if started{
                    playerManager.scrubState = .scrubStarted
                }
            }, track: {
                Capsule()
                    .foregroundColor(.init(red: 0.9, green: 0.9, blue: 0.9))
                    .frame(width: proxy.size.width, height: 5)
            }, fill: {
                Capsule()
                    .foregroundColor(.red)
            }, thumb: {
                Circle()
                    .foregroundColor(.white)
                    .overlay {
                        Text(playerManager.currentTime.stringFromTimeInterval())
                            .fixedSize()
                            .foregroundColor(.white)
                            .offset(y: -30)
                    }
            }, thumbSize:
                    .init(width: 20, height: 20)
            )
        }
        .frame(height: 30)
    }
    
    
    private var rateButton: some View{
        Text(selectedRate.rawValue)
            .foregroundColor(.white)
            .font(.headline.weight(.bold))
            .padding(.horizontal)
            .onTapGesture {
                showRatePicker.toggle()
            }
    }
    
    private var ratePicker: some View{
        VStack(spacing: 10){
            ForEach(EnumRate.allCases, id: \.self) { rate in
                Text(rate.rawValue)
                    .foregroundColor(rate == selectedRate ? .orange : .white)
                    .padding(.vertical, 5)
                    .font(.body.weight(.bold))
                    .onTapGesture {
                        selectedRate = rate
                        showRatePicker.toggle()
                        playerManager.setRateAndPlay(rate.value)
                    }
            }
        }
        .padding(.vertical, 10)
        .frame(width: 50)
        .background(Material.ultraThinMaterial, in: Capsule())
        .offset(y: -140)
        .padding(.horizontal, 9)
    }
}




enum EnumRate: String, CaseIterable{
    
    case x2 = "2x"
    case x15 = "1.5"
    case x1 = "1x"
    case x125 = "1.25"
    case x12 = "1/2"
    case x14 = "1/4"
    case x18 = "1/8"
    
    var value: Float{
        switch self {
        case .x2: return 2
        case .x15: return 1.5
        case .x1: return 1
        case .x125: return 1.25
        case .x12: return 0.5
        case .x14: return 0.25
        case .x18: return 0.125
        }
    }
}
