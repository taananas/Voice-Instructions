//
//  VideoControlsView.swift
//  Voice Instructions
//
//  Created by Bogdan Zykov on 08.06.2023.
//

import SwiftUI

struct VideoControlsView: View {
    @ObservedObject var playerManager: VideoPlayerManager
    var video: Video
    private let thumbRadius: CGFloat = 30
    var body: some View {
        VStack{
            timeSlider
            HStack(spacing: 16) {
                playPauseButton
                Spacer()
            }
        }
        .vBottom()
        .padding()
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
}



