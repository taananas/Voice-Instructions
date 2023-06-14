//
//  VideoPreview.swift
//  Voice Instructions
//
//

import SwiftUI

struct VideoPreview: View {
    @State var rangeDuration: ClosedRange<Double> = 0...1
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VideoPreviewViewModel()
    @StateObject private var playerManager = VideoPlayerManager()
    var url: URL?
    var body: some View {
        ZStack{
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    if let video = viewModel.video{
                        PlayerRepresentable(player: playerManager.videoPlayer)
                    }
                    controlsSection(proxy)
                }
                .task {
                    guard let url else {return}
                    let video = await viewModel.setVideo(url: url, size: proxy.size)
                    playerManager.loadVideo(video)
                    self.rangeDuration = video.rangeDuration
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            header
        }
        .preferredColorScheme(.dark)
    }
}

struct VideoPreview_Previews: PreviewProvider {
    static var previews: some View {
        VideoPreview()
    }
}

extension VideoPreview{
    private var header: some View{
        Text("Video preview")
            .font(.title3.bold())
            .padding()
    }
    
    private func controlsSection(_ proxy: GeometryProxy) -> some View{
        VStack{
            if let video = viewModel.video {
                
                ZStack{
                    thumbnailsImagesSection(proxy)
                    RangedSliderView(value: $rangeDuration, bounds: video.rangeDuration, onEndChange: {
                        setOnChangeTrim(video)
                    }, thumbView: {
                        Rectangle()
                            .blendMode(.destinationOut)
                        InternalSlider(value: $playerManager.currentTime, in: rangeDuration, height: 70, width: 6, step: 0.01) {
                            playerManager.seek(playerManager.currentTime)
                        }
                    })
                }
                .frame(height: 70)
                .padding(.horizontal)
                .padding(.top)
            }

            Button {
                playerManager.action(rangeDuration)
            } label: {
                Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 25)
                    .foregroundColor(.white)
            }
            .hCenter()
            .padding(.top, 5)
            .overlay {
                HStack{
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    Spacer()
                    Button {
                        
                    } label: {
                        Text("Use")
                    }
                }
                .foregroundColor(.white)
                .font(.title3.weight(.medium))
            }
            
        }
        .padding([.horizontal, .top])
    }
    
    private func setOnChangeTrim(_ video: Video){
        playerManager.currentTime = video.rangeDuration.upperBound
        playerManager.seek(playerManager.currentTime)
    }
    
    @ViewBuilder
    private func thumbnailsImagesSection(_ proxy: GeometryProxy) -> some View{
        HStack(spacing: 0){
            ForEach(viewModel.thumbnailsImages) { trimData in
                if let image = trimData.image{
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: (proxy.size.width - 64) / CGFloat(viewModel.thumbnailsImages.count), height: 70)
                        .clipped()
                }
            }
        }
    }
}
