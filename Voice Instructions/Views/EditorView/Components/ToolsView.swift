//
//  ToolsView.swift
//  Voice Instructions
//
//

import SwiftUI

struct ToolsView: View {
    @ObservedObject var layerManager: VideoLayerManager
    var body: some View {
        HStack(alignment: .top, spacing: 0){
            
            if !layerManager.isEmptyLayer{
                VStack(spacing: 16) {
                    removeButton
                    undoButton
                }
            }
        
            Spacer()
            
            toolButtons
        }
        .padding(.horizontal, 18)
    }
}

struct ToolsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.secondary
            ToolsView(layerManager: VideoLayerManager())
                .vTop()
        }
    }
}

extension ToolsView{
    
    private var removeButton: some View{
        Button {
            layerManager.removeAll()
        } label: {
            buttonLabel("trash.fill")
        }
    }
    
    @ViewBuilder
    private var undoButton: some View{
        if layerManager.undoIsActive{
            Button {
                layerManager.undo()
            } label: {
                buttonLabel("arrow.uturn.backward")
            }
       }
    }
    
    
    private var toolButtons: some View{
        ToolDropdownMenu(selectedTool: $layerManager.selectedTool)
    }
    
    private func buttonLabel(_ image: String) -> some View{
        Image(systemName: image)
            .resizable()
            .scaledToFit()
            .frame(width: 14, height: 14)
            .padding(12)
            .background(Color.black.opacity(0.25), in: Circle())
            .foregroundColor(.white)
            .bold()
    }
}

enum ToolEnum: Int, CaseIterable{
    case arrow, line, angle, polyLine, circle, rectangle, timer
}
