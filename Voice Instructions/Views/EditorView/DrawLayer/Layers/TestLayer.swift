//
//  TestLayer.swift
//  Voice Instructions
//
//  Created by Bogdan Zykov on 15.06.2023.
//

import SwiftUI

struct TestLayer: View {
    var body: some View {
        ZStack{
           
           // Color.secondary
            
            ZStack{
                // video
                Color.blue.opacity(0.5)
                
                //layers
                Rectangle()
                    .frame(width: 20, height: 20)
                    .offset(x: 0, y: -100)
            }
           
                .mask {
                    ZStack{
                        Rectangle()
                            .frame(height: 200)
                            .blendMode(.destinationOver)
                    }
                }
           
            
           
            
            
//            Rectangle()
//                .fill(Color.black.opacity(0.7))
//                .frame(width: 200, height: 200)
            
        }
       //.compositingGroup()
    }
}

struct TestLayer_Previews: PreviewProvider {
    static var previews: some View {
        TestLayer()
    }
}
