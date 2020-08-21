//
//  ViewController.swift
//  SimpleApp
//
//  Created by eduardo mancilla on 26/06/20.
//  Copyright © 2020 eduardo mancilla. All rights reserved.
//

import UIKit
import ReplayKit
import Photos
import os

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let groupDefaults = UserDefaults(suiteName: "group.com.blacker.extension")
        groupDefaults?.set("A text", forKey: "extensionText")
        
        
        if #available(iOS 12.0, *) {
            let broadCastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 100, y: 200, width: 160, height: 150))
            
            broadCastPicker.preferredExtension = "black.dev.SimpleApp.SimpleAppBroadCastUploadExtension"

            
            self.view.addSubview(broadCastPicker)
        } else {
            //no podemos inicial la captura de pantalla en versiones menores a ios 12
        }
        checkPhotoLibraryPermission()
        if #available(iOS 12.0, *) {
            os_log(.debug, "Logger", "abcdef")
        } else {
            // Fallback on earlier versions
        }
    }


    func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized: break
        //handle authorized status
        case .denied, .restricted : break
        //handle denied status
        case .notDetermined:
            // ask for permissions
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized: break
                // as above
                case .denied, .restricted: break
                // as above
                case .notDetermined: break
                // won't happen but still
                }
            }
        }
    }
}

