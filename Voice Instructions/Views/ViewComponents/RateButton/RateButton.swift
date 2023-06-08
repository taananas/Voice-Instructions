//
//  RateButton.swift
//  Voice Instructions
//
//  Created by Bogdan Zykov on 08.06.2023.
//

import SwiftUI

struct RateButton: View {
    @State var selectedRate: EnumRate = .x1
    @State private var show: Bool = false
    
    let onChange: (Float) -> Void
    
    var body: some View {
        
        Text(selectedRate.rawValue)
            .foregroundColor(.white)
            .font(.body.weight(.bold))
            .onTapGesture {
                show.toggle()
            }
            
            .overlay {
                Group{
                    if show{
                        VStack(spacing: 10){
                            ForEach(EnumRate.allCases, id: \.self) { rate in
                                Text(rate.rawValue)
                                    .foregroundColor(rate == selectedRate ? .orange : .white)
                                    .padding(.vertical, 5)
                                    .font(.body.weight(.bold))
                                    .onTapGesture {
                                        selectedRate = rate
                                        show.toggle()
                                        onChange(rate.value)
                                    }
                            }
                        }
                        .padding(.vertical, 10)
                        .frame(width: 60)
                        .background(Material.ultraThinMaterial, in: Capsule())
                        .offset(y: -80)
                    }
                }
                .animation(.default, value: show)
            }
        
    }
}

struct RateButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack{
            Color.black
            RateButton(){_ in}
        }
    }
}


enum EnumRate: String, CaseIterable{
    
    case x2 = "2x"
    case x15 = "1.5"
    case x1 = "1x"
    case x125 = "1.25"
    case x12 = "1/2"
    case x14 = "1/4"
    case x18 = "1/8"
    
    var value: Float{
        switch self {
        case .x2: return 2
        case .x15: return 1.5
        case .x1: return 1
        case .x125: return 1.25
        case .x12: return 0.5
        case .x14: return 0.25
        case .x18: return 0.125
        }
    }
}
