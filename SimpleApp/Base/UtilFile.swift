//
//  UtilFile.swift
//  SimpleApp
//
//  Created by eduardo mancilla on 26/08/20.
//  Copyright © 2020 eduardo mancilla. All rights reserved.
//

import Foundation

class UtilFile {
     private let fileManager = FileManager.default
    
    func getSharedFolder(namefile: String) -> URL? {
        let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Shared.Constantes.groupName)?
            .appendingPathComponent(namefile)
        return url
    }
    
    func fileExists(atPath path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
    
    @discardableResult
    func removeItem(atPath path: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch let error as NSError {
            NSLog("WARN:::Cannot delete existing file: %@, error: %@", path, error.debugDescription)
        }
        return false
    }
    
    func createDirectory(atPath path: String) {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("WARN:::Cannot create file: %@, error: %@", path, error.debugDescription)
        }
    }
    
}
