//
//  VideoLayerManager.swift
//  Voice Instructions
//
//

import SwiftUI

class VideoLayerManager: ObservableObject {
   
    ///Selected color for tool
    @Published var selectedColor: Color = .red
    @Published var selectedTool: ToolEnum?
    
    ///free lines
    @Published private(set) var strokes = [Stroke]()
    
    /// shapes circle and rectangle
    @Published var shapes = [DragShape]()
    
    var undoManager: UndoManager?
    
    
    var isActiveTool: Bool{
        selectedTool != nil
    }
  
    var undoIsActive: Bool{
        undoManager?.canUndo ?? false
    }
    
    var isEmptyLayer: Bool{
        strokes.isEmpty && shapes.isEmpty
    }
    
    func undo() {
        objectWillChange.send()
        undoManager?.undo()
    }
    
    func removeAll(){
        removeAllLines()
        removeAllShapes()
    }
    
}

//MARK: - Free line logic

extension VideoLayerManager{
    
    func addLine(value: DragGesture.Value){
        let point = value.location
        if value.translation.width + value.translation.height == 0{
            addLineWithUndo()
        }else{
            updatePoints(point)
        }
    }
    
    private func removeAllLines(){
        strokes.removeAll()
    }
    
    private func addLineWithUndo(){
        undoManager?.registerUndo(withTarget: self) { manager in
            manager.removeLastLine()
        }
        strokes.append(Stroke(color: selectedColor))
    }
    
    private func removeLastLine(){
        guard !strokes.isEmpty else {return}
        strokes.removeLast()
    }
    
    
    private func updatePoints(_ point: CGPoint){
        guard !strokes.isEmpty else {return}
        strokes[strokes.count - 1].points.append(point)
    }
}

//MARK: - Shapes logic
extension VideoLayerManager{
    
    
    func addShape(location: CGPoint){
        if isActiveShape{
            deactivateAllShape()
            return
        }
        let newShape = DragShape(type: .circle, startLocation: location, color: selectedColor)
        undoManager?.registerUndo(withTarget: self) { manager in
            manager.removeLastShape()
        }
        shapes.append(newShape)
    }
    
    
    var isActiveShape: Bool{
        shapes.contains(where: {$0.isActive})
    }

    func deactivateAllShape(){
        shapes.indices.forEach { index in
            shapes[index].isActive = false
        }
    }
    
    private func removeLastShape(){
        guard !shapes.isEmpty else {return}
        shapes.removeLast()
    }
    
    private func removeAllShapes(){
        shapes.removeAll()
    }
}
