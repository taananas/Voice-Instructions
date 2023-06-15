//
//  ToolDropdownMenu.swift
//  Voice Instructions
//
//

import SwiftUI

struct ToolDropdownMenu: View {
    @State private var isOpenTool: Bool = false
    @State private var tools = ToolEnum.allCases.map({Tool(type: $0)})
    @Binding var selectedTool: ToolEnum?
    @Namespace private var animation
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: isOpenTool || selectedTool != nil ? "xmark" : "pencil")
                .font(.title3.weight(.bold))
                .onTapGesture {
                    if selectedTool != nil{
                        selectedTool = nil
                    }else{
                        isOpenTool.toggle()
                    }
                }
            
            if let selectedTool, !isOpenTool{
                toolCell(selectedTool)
                chevronDownButton
            }
            if isOpenTool{
                ForEach(tools) { tool in
                    toolCell(tool.type)
                        .onTapGesture {
                            selectedTool = tool.type
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
        .animation(.spring(), value: isOpenTool)
        .animation(.spring(), value: selectedTool)
    }
}

struct ToolDropdownMenu_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.secondary
            ToolDropdownMenu(selectedTool: .constant(.angle))
                .vTop()
        }
    }
}

extension ToolDropdownMenu{
    
    private func toolCell(_ toolType: ToolEnum) -> some View{
        Text("\(toolType.rawValue)")
            .hCenter()
            .overlay(alignment: .leading) {
                if toolType == selectedTool{
                    Image(systemName: "arrowtriangle.left.fill")
                        .matchedGeometryEffect(id: "CellIcon", in: animation)
                        .font(.system(size: 8))
                }
            }
    }
    
    private var chevronDownButton: some View{
        Image(systemName: isOpenTool ? "chevron.up" : "chevron.down")
            .font(.body.bold())
            .padding(.top, 10)
            .onTapGesture {
                isOpenTool.toggle()
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
