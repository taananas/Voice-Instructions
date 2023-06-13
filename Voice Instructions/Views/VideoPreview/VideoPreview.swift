//
//  VideoPreview.swift
//  Voice Instructions
//
//
import AVKit
import SwiftUI

struct VideoPreview: View {
    var url: URL?
    var body: some View {
        ZStack{
            Color.secondary.ignoresSafeArea()
            if let url{
                VideoPlayer(player: .init(url: url))
            }else{
                Text("Failed set url!")
            }
        }
    }
}

struct VideoPreview_Previews: PreviewProvider {
    static var previews: some View {
        VideoPreview()
    }
}
