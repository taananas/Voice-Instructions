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
            HStack(spacing: 16) {
                playPauseButton
                Spacer()
                rateButton
//                ScrubbingBarView(duration: playerManager.video?.totalDuration ?? 60, time: $playerManager.currentTime)
               // RateButton(onChange: playerManager.setRateAndPlay)
            }
        }
        .vBottom()
        .padding(.horizontal, 18)
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
                .padding()
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

    }
    
    
    private var timeSlider: some View{
        
        GeometryReader { proxy in
            CustomSlider(value: Binding(get: {
                playerManager.currentTime
            }, set: { newValue in
                playerManager.currentTime = newValue
                playerManager.scrubState = .scrubEnded(newValue)
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
            .font(.body.weight(.bold))
            .padding(.leading, 10)
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
        .offset(y: -100)
        .padding(.horizontal, 9)
    }
}



