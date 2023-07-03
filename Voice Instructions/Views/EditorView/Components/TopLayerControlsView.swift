//
//  TopLayerControlsView.swift
//  Voice Instructions
//
//

import SwiftUI

struct TopLayerControlsView: View {
    @ObservedObject var layerManager: VideoLayerManager
    @ObservedObject var playerManager: VideoPlayerManager
    @State private var selectedRate: EnumRate = .x1
    @State private var showRatePicker: Bool = false
    private var isIPad: Bool{
        UIDevice.current.isIPad
    }
    var body: some View {
        ZStack{
            HStack(alignment: .top) {
                UndoButtons(layerManager: layerManager)
                    .padding(.top, isIPad ? 110 : 70)
                Spacer()
                ToolDropdownMenu(selectedTool: $layerManager.selectedTool, selectedColor: $layerManager.selectedColor, onOpen: closeRatePicker)
            }
            .vTop()
            rateButton
                .overlay {
                    Group{
                        if showRatePicker{
                            ratePicker
                        }
                    }
                    .animation(.default, value: showRatePicker)
                }
                .hTrailing()
                .vBottom()
        }
        .padding(.horizontal, Constants.horizontalPrimaryPadding)
    }
}

struct TopLayerControlsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack{
            Color.white.ignoresSafeArea()
            TopLayerControlsView(layerManager: VideoLayerManager(), playerManager: VideoPlayerManager())
        }
      
    }
}

extension TopLayerControlsView{
    
    
    
    private var rateButton: some View{
        Text(selectedRate.rawValue)
            .foregroundColor(.white)
            .font(.headline.weight(.bold))
            .padding(.horizontal)
            .onTapGesture {
                showRatePicker.toggle()
            }
    }
    
    private var ratePicker: some View{
        VStack(spacing: 10){
            ForEach(EnumRate.allCases, id: \.self) { rate in
                Text(rate.rawValue)
                    .foregroundColor(rate == selectedRate ? .orange : .white)
                    .padding(.vertical, 5)
                    .font(.body.weight(.bold))
                    .onTapGesture {
                        selectedRate = rate
                        showRatePicker.toggle()
                        playerManager.setRateAndPlay(rate.value)
                    }
            }
        }
        .padding(.vertical, 10)
        .frame(width: 45)
        .background(Color.black.opacity(0.25), in: Capsule())
        .offset(y: -220)
    }
    
    
    private func closeRatePicker(_ isOpen: Bool){
        if showRatePicker{
            showRatePicker = false
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
