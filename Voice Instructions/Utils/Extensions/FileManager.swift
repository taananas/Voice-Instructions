//
//  FileManager.swift
//  Voice Instructions
//
//

import Foundation


extension FileManager{
    
        
    func removeFileExists(for url: URL){
        if fileExists(atPath: url.path){
            do{
                try removeItem(at: url)
            }catch{
                print("Error to remove item", error.localizedDescription)
            }
        }
    }
}
