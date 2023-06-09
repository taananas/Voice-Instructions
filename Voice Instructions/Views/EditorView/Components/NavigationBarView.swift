//
//  NavigationBarView.swift
//  Voice Instructions
//
//  Created by Bogdan Zykov on 09.06.2023.
//

import SwiftUI

struct NavigationBarView: View {
    @ObservedObject var playerManager: VideoPlayerManager
    @State private var isPresented: Bool = false
    @State private var isRecord: Bool = false
    var body: some View {
        HStack{
            closeButton
                .hLeading()
                .overlay {
                    HStack(spacing: 30) {
                        stopButton
                        micButton
                    }
                }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
        .background(Color.black.opacity(0.25))
        .alert("Remove video", isPresented: $isPresented) {
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
            NavigationBarView(playerManager: VideoPlayerManager())
        }
    }
}

extension NavigationBarView{
    
    private var closeButton: some View{
        Button {
            isPresented.toggle()
        } label: {
            buttonLabel("xmark")
        }
    }
    
    private var micButton: some View{
        Button {
            isRecord.toggle()
        } label: {
            buttonLabel(isRecord ? "pause.fill" : "mic.fill")
        }
    }
    
    private var stopButton: some View{
        Button {
            
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
