//
//  EditorView.swift
//  Voice Instructions
//
//

import SwiftUI
import PhotosUI
import AVKit

struct EditorView: View {
    @State var showLayer: Bool = false
    @StateObject var playerManager = VideoPlayerManager(fromStorage: true)
    @StateObject var recorderManager = ScreenRecorderManager()
    var body: some View {
        ZStack{
            Color.black.ignoresSafeArea()
            switch playerManager.loadState{
            case .loading:
                ProgressView()
            case .loaded:
                playerLayers
            case .unknown:
                pickerButton
            case.failed:
                Text("Error")
            }
        }
        .onChange(of: playerManager.selectedItem, perform: setVideo)
        .safeAreaInset(edge: .top, alignment: .center, spacing: 0){
            navBarView
        }
        .fullScreenCover(isPresented: $recorderManager.showPreview) {
            VideoPreview(url: recorderManager.finalURl.value)
        }
    }
}

struct EditorView_Previews: PreviewProvider {
    @StateObject static var playerManager = VideoPlayerManager()
    static var previews: some View {
        EditorView(playerManager: playerManager)
    }
}


extension EditorView{
    
    
    
    private var playerLayers: some View{
        ZStack{
            PlayerRepresentable(player: playerManager.videoPlayer, videoSize: playerManager.video?.originalSize)
                 .ignoresSafeArea()
            if showLayer{
                DrawVideoLayer(playerManager: playerManager)
            }
            
        }
        .overlay(alignment: .bottom) {
            bottomControlsView
        }
        .overlay(alignment: .top) {
            ToolsView()
                .padding(.top, 30)
        }
    }
    
    private var pickerButton: some View{
        PhotosPicker("Pick Video",
                     selection: $playerManager.selectedItem,
                     matching: .videos,
                     photoLibrary: .shared())
        .foregroundColor(.white)
    }

}

// safeAreaInset content
extension EditorView{
    
    @ViewBuilder
    private var navBarView: some View{
        if playerManager.loadState == .loaded{
            NavigationBarView(recorderManager: recorderManager, playerManager: playerManager)
        }
    }
    
    @ViewBuilder
    private var bottomControlsView: some View{
        if let video = playerManager.video, playerManager.loadState == .loaded{
            VideoControlsView(playerManager: playerManager, video: video)
        }
    }
}

extension EditorView{
    private func setVideo(_ item: PhotosPickerItem?){
         Task{
            await playerManager.loadVideoItem(item)
         }
     }
}
