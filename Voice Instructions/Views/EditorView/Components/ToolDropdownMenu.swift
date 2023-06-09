//
//  ToolDropdownMenu.swift
//  Voice Instructions
//
//  Created by Bogdan Zykov on 09.06.2023.
//

import SwiftUI

struct ToolDropdownMenu: View {
    @State private var isFoldTools: Bool = false
    @State private var isTapTool: Bool = false
    @State private var tools = ToolEnum.allCases.map({Tool(type: $0)})
    @State private var selectedTools: ToolEnum?
    @Namespace private var animation
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: isTapTool || selectedTools != nil ? "xmark" : "pencil")
                .font(.title3.weight(.bold))
                .onTapGesture {
                    if selectedTools != nil && isFoldTools{
                        selectedTools = nil
                    }else{
                        isTapTool.toggle()
                    }
                }
            
            if let selectedTools, isFoldTools, !isTapTool{
                toolCell(selectedTools)
                chevronDownButton
            }
            if isTapTool{
                ForEach(tools) { tool in
                    toolCell(tool.type)
                        .onTapGesture {
                            selectedTools = tool.type
                        }
                }
                chevronDownButton
            }
        }
        .frame(width: 50)
        .padding(.vertical, 15)
        .background{
            Capsule()
                .fill(Color.black.opacity(0.25))
        }
        .foregroundColor(.white)
        .animation(.spring(), value: isTapTool)
        .animation(.spring(), value: isFoldTools)
        .animation(.spring(), value: selectedTools)
    }
}

struct ToolDropdownMenu_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.secondary
            ToolDropdownMenu()
                .vTop()
        }
    }
}

extension ToolDropdownMenu{
    
    private func toolCell(_ toolType: ToolEnum) -> some View{
        Text("\(toolType.rawValue)")
            .hCenter()
            .overlay(alignment: .leading) {
                if toolType == selectedTools{
                    Image(systemName: "arrowtriangle.left.fill")
                        .matchedGeometryEffect(id: "CellIcon", in: animation)
                        .font(.system(size: 8))
                }
            }
    }
    
    private var chevronDownButton: some View{
        Image(systemName: isFoldTools ? "chevron.down" : "chevron.up")
            .font(.body.bold())
            .padding(.top, 10)
            .onTapGesture {
                isTapTool = false
                isFoldTools.toggle()
            }
    }
    
    struct Tool: Identifiable{
        var id: Int { type.rawValue }
        var type: ToolEnum
        var isAnimate: Bool = false
    }
    
    enum ToolState: Int{
        case open, openFold, closeFolder
    }
}
