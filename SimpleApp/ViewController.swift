//
//  ViewController.swift
//  SimpleApp
//
//  Created by eduardo mancilla on 26/06/20.
//  Copyright © 2020 eduardo mancilla. All rights reserved.
//

import os
import Photos
import ReplayKit
import UIKit

 @available(iOS 12.0, *)
class ViewController: UIViewController {
    var broadCastPicker: RPSystemBroadcastPickerView?
    var broadcastSession : NSObject?

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        let groupDefaults = UserDefaults(suiteName: "group.com.blacker.extension")
        
        groupDefaults?.set("A text", forKey: "extensionText")

        if #available(iOS 12.0, *) {
            groupDefaults?.set("videoRecordScreen", forKey: "video_name")
            
            broadCastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 100, y: 200, width: 160, height: 150))
            broadCastPicker!.preferredExtension = "black.dev.SimpleApp.SimpleAppBroadCastUploadExtension"
            self.view.addSubview(broadCastPicker!)
            
            extensionContext?.loadBroadcastingApplicationInfo(completion: { (bundleID, displayName, appIcon) in
                NSLog("La extension ha sido terminada o completada....")
            })

            
            
        } else {
            // no podemos inicial la captura de pantalla en versiones menores a ios 12
        }
        loadData()
    }
    
    private func loadData() {
        let sharedContainerURL: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.blacker.extension")
        NSLog("sharedContainerURL = \(String(describing: sharedContainerURL))")
        if let sourceURL: URL = sharedContainerURL?.appendingPathComponent("Records/test_capture_video.mp4") {
            if let destinationURL: URL = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("test_capture_video.mp4") {
                do {
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                } catch (let error) {
                    print("Cannot copy item at \(sourceURL) to \(destinationURL): \(error)")
                }
            }
        }
    }
    
    @IBAction func clickButton(_ sender: UIButton) {
        
    }
}
