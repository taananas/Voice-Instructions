//
//  UndoButtons.swift
//  Voice Instructions
//
//

import SwiftUI

struct UndoButtons: View {
    @ObservedObject var layerManager: VideoLayerManager
    var body: some View {
        Group{
            if !layerManager.isEmptyLayer{
                VStack(spacing: 16) {
                    removeButton
                    undoButton
                }
                .hLeading()
            }
        }
    }
}

struct ToolsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.secondary
            UndoButtons(layerManager: VideoLayerManager())
                .vTop()
        }
    }
}

extension UndoButtons{
    
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
    
    
    var shapeType: DragShape.ShapeType?{
    
        switch self {
        case .arrow: return .arrow
        case .line: return .line
        case .circle: return .circle
        case .rectangle: return .rectangle
        default: return nil
        }
        
    }
}
