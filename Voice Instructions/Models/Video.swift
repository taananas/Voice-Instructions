//
//  Video.swift
//  Voice Instructions
//
//

import Foundation

struct Video: Identifiable, Codable{
    
    var id: UUID = UUID()
    private var url: URL
    let originalDuration: Double
    var rangeDuration: ClosedRange<Double>
    
    var totalDuration: Double{
        rangeDuration.upperBound - rangeDuration.lowerBound
    }
    
    init(url: URL, originalDuration: Double){
        self.url = url
        self.originalDuration = originalDuration
        self.rangeDuration = 0...originalDuration
    }
    
    var fullPath: URL{
        FileManager.default.createVideoPath(with: url.lastPathComponent) ?? url
    }
}

extension Video{
    
    static let mock = Video(url: URL(string: "url")!, originalDuration: 10)
    
}
