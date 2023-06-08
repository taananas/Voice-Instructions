//
//  Video.swift
//  Voice Instructions
//
//

import Foundation

struct Video: Identifiable{
    
    var id: UUID = UUID()
    var url: URL
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
}

extension Video{
    
    static let mock = Video(url: URL(string: "url")!, originalDuration: 10)
    
}
