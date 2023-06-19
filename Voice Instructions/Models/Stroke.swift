//
//  Stroke.swift
//  Voice Instructions
//
//  Created by Bogdan Zykov on 19.06.2023.
//

import Foundation
import SwiftUI

struct Stroke: Identifiable {
    var id: UUID = UUID()
    var points = [CGPoint]()
    var color = Color.red
    var width: CGFloat = 3
}
