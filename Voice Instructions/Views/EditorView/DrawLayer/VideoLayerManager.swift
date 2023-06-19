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
    
    /// timers
    @Published var timers = [TimerModel]()
    
    var undoManager: UndoManager?
    
    
    var isActiveTool: Bool{
        selectedTool != nil
    }
  
    var undoIsActive: Bool{
        undoManager?.canUndo ?? false
    }
    
    var isEmptyLayer: Bool{
        strokes.isEmpty && shapes.isEmpty && timers.isEmpty
    }
    
    func undo() {
        objectWillChange.send()
        undoManager?.undo()
    }
    
    func removeAll(){
        removeAllLines()
        removeAllShapes()
        removeAllTimers()
    }
    
    func deactivateAllObjects(){
        shapes.indices.forEach { index in
            shapes[index].deactivate()
        }
        timers.indices.forEach { index in
            timers[index].deactivate()
        }
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
    
    
    func addShape(value: DragGesture.Value){
        let point = value.location
        
        let width = abs(value.translation.width * 1.5)
        let height = abs(value.translation.height * 1.5)
        
        if width + height > 0{
            updateShape(width: width, height: height, point)
        }else{
            addShapeWithUndo(point)
        }
    }
    
    func removeShape(_ id: UUID){
        shapes.removeAll(where: {$0.id == id})
    }
    
    var isActiveShape: Bool{
        shapes.contains(where: {$0.isActive})
    }
    
    private func addShapeWithUndo(_ location: CGPoint){
        if isActiveShape{
            deactivateAllObjects()
            return
        }
        guard let type = selectedTool?.shapeType else {return}
        let newShape = DragShape(type: type, location: location, color: selectedColor, size: .init(width: 20, height: 20), endLocation: location)
        undoManager?.registerUndo(withTarget: self) { manager in
            manager.removeLastShape()
        }
        shapes.append(newShape)
    }
    
    private func updateShape(width: CGFloat, height: CGFloat, _ location: CGPoint){
        guard !shapes.isEmpty else {return}
        let index = shapes.count - 1
        if shapes[index].isShapeType {
            if width > 10 && height > 10{
                shapes[index].size = .init(width: width, height: height)
            }
        }else{
            shapes[index].endLocation = location
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

//MARK: - Timers logic
extension VideoLayerManager{
    
    func addTimer(value: DragGesture.Value, activateTime: Double){
        let point = value.location
        let timer = TimerModel(position: point, activateTime: activateTime, color: selectedColor)
        undoManager?.registerUndo(withTarget: self) { manager in
            manager.removeLastTimer()
        }
        timers.append(timer)
    }
    
    func removeTimer(_ id: UUID){
        timers.removeAll(where: {$0.id == id})
    }
    
    private func removeLastTimer(){
        guard !timers.isEmpty else {return}
        timers.removeLast()
    }
    
    private func removeAllTimers(){
        timers.removeAll()
    }
}
