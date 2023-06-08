//
//  Double.swift
//  Voice Instructions
//
//

extension Double{
    
    
    func stringFromTimeInterval() -> String {

        let time = Int(self)

        let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 100)
        let seconds = time % 60
        let minutes = (time / 60) % 60
    
        if minutes == 0{
            return String(format: "%0.2d.%0.2d", seconds, ms)
        }else{
            return String(format: "%0.2d:%0.2d.%0.2d", minutes, seconds, ms)
        }
    }
    
    func formatterTimeString() -> String{
        let minutes = Int(self / 60)
          let seconds = Int(self.truncatingRemainder(dividingBy: 60))
          return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
