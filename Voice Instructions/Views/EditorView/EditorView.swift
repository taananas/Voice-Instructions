//
//  EditorView.swift
//  Voice Instructions
//
//

import SwiftUI
import PhotosUI
import AVKit

struct EditorView: View {
   
    @StateObject var playerManager = VideoPlayerManager()
    var body: some View {
        ZStack{
            Color.black.ignoresSafeArea()
            switch playerManager.loadState{
            case .loading:
                ProgressView()
            case .loaded:
                playerSectionView
            case .unknown:
                pickerButton
            case.failed:
                Text("Error")
            }
        }
        .onChange(of: playerManager.selectedItem, perform: setVideo)
    }
}

struct EditorView_Previews: PreviewProvider {
    @StateObject static var playerManager = VideoPlayerManager()
    static var previews: some View {
        EditorView(playerManager: playerManager)
    }
}


extension EditorView{
    
    
    
    private var playerSectionView: some View{
        ZStack{
            PlayerRepresentable(player: playerManager.videoPlayer)
                 .ignoresSafeArea()
            if let video = playerManager.video{
                VideoControlsView(playerManager: playerManager, video: video)
                    .vBottom()
            }
            
        
        }
        .overlay(alignment: .topLeading) {
            removeButton
        }
    }
    
    private var pickerButton: some View{
        PhotosPicker("Pick Video",
                     selection: $playerManager.selectedItem,
                     matching: .videos,
                     photoLibrary: .shared())
        .foregroundColor(.white)
    }
    
   private func setVideo(_ item: PhotosPickerItem?){
        Task{
           await playerManager.loadVideoItem(item)
        }
    }
    
    private var removeButton: some View{
        CloseButton(onRemove: playerManager.removeVideo)
    }
}


extension EditorView{
    struct CloseButton: View{
        @State private var isPresented: Bool = false
        let onRemove: () -> Void
        var body: some View{
            Button {
                isPresented.toggle()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Material.ultraThinMaterial, in: Circle())
                    .padding()
            }
            .alert("Remove video", isPresented: $isPresented) {
                Button("Cancel", role: .cancel, action: {})
                Button("Remove", role: .destructive, action: onRemove)
            } message: {
                Text("Are you sure you want to delete the video?")
            }
        }
    }
}
