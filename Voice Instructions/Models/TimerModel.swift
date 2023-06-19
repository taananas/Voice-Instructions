//
//  TimerModel.swift
//  Voice Instructions
//
//  Created by Bogdan Zykov on 19.06.2023.
//

import SwiftUI

struct TimerModel: Identifiable{
    var id: UUID = UUID()
    var position: CGPoint
    var isSelected: Bool = false
    var activateTime: Double
    var color: Color
    
    mutating func setNewTime(_ time: Double){
        activateTime = time
    }
    
    mutating func deactivate(){
        isSelected = false
    }
}

