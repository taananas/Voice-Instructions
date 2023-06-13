//
//  NavigationBarView.swift
//  Voice Instructions
//
//

import SwiftUI

struct NavigationBarView: View {
    @ObservedObject var recorderManager: ScreenRecorderManager
    @ObservedObject var playerManager: VideoPlayerManager
    @State private var isPresentedAlert: Bool = false
    var body: some View {
        HStack{
            closeButton
                .hLeading()
                .overlay {
                    HStack(spacing: 30) {
                        if recorderManager.recorderIsActive{
                            stopButton
                        }
                        micButton
                    }
                }
        }
        .padding(.horizontal, 18)
        .padding(16)
        .background(Color.black.opacity(0.25))
        .alert("Remove video", isPresented: $isPresentedAlert) {
            Button("Cancel", role: .cancel, action: {})
            Button("Remove", role: .destructive, action: playerManager.removeVideo)
        } message: {
            Text("Are you sure you want to delete the video?")
        }
    }
}

struct NavigationBarView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.secondary.ignoresSafeArea()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            NavigationBarView(recorderManager: ScreenRecorderManager(), playerManager: VideoPlayerManager())
        }
    }
}

extension NavigationBarView{
    
    private var closeButton: some View{
        Button {
            if recorderManager.recorderIsActive{
                recorderManager.removeAll()
            }else{
                isPresentedAlert.toggle()
            }
        } label: {
            buttonLabel("xmark")
        }
    }
    
    private var micButton: some View{
        Button {
            if recorderManager.isRecord{
                recorderManager.pause()
            }else{
                recorderManager.startRecoding()
            }
        } label: {
            buttonLabel(recorderManager.isRecord ? "pause.fill" : "mic.fill")
        }
    }
    
    private var stopButton: some View{
        Button {
            recorderManager.stop()
        } label: {
            buttonLabel("stop.fill", foregroundColor: .red)
        }
    }
    
    private func buttonLabel(_ image: String, foregroundColor: Color = .white) -> some View{
        Image(systemName: image)
            .resizable()
            .scaledToFit()
            .frame(width: 14, height: 14)
            .padding(12)
            .background(Color.white.opacity(0.1), in: Circle())
            .foregroundColor(foregroundColor)
            .bold()
        
    }
    
}
