//
//  ViewController.swift
//  SimpleApp
//
//  Created by eduardo mancilla on 26/06/20.
//  Copyright © 2020 eduardo mancilla. All rights reserved.
//

import ReplayKit
import UIKit
import AVKit

class ViewController: UIViewController {
    private let videoName: String = "videoRecordScreen"
    private var videoURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        let groupDefaults = UserDefaults(suiteName: "group.com.blacker.extension")
        
        groupDefaults?.set("A text", forKey: "extensionText")
        
        if #available(iOS 12.0, *) {
            groupDefaults?.set(videoName, forKey: "video_name")
            
            let broadCastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 100, y: 200, width: 160, height: 150))
            broadCastPicker.preferredExtension = "black.dev.SimpleApp.SimpleAppBroadCastUploadExtension"
            self.view.addSubview(broadCastPicker)
            
            extensionContext?.loadBroadcastingApplicationInfo(completion: { _, _, _ in
                NSLog("La extension ha sido terminada o completada....")
            })
            
        } else {
            // no podemos inicial la captura de pantalla en versiones menores a ios 12
        }
        loadData()
    }
    
    private func loadData() {
        let sharedContainerURL: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.blacker.extension")
        guard let sourceURL: URL = sharedContainerURL?.appendingPathComponent("Records/\(videoName).mp4") else { return }
        guard let destinationURL: URL = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("\(videoName).mp4") else { return }
        
        let fileManager = FileManager.default
        
        let finalFilename = destinationURL.path
        if fileManager.fileExists(atPath: finalFilename) {
            NSLog("WARN:::The file: \(finalFilename) exists, will delete the existing file")
            do {
                try fileManager.removeItem(atPath: finalFilename)
            } catch let error as NSError {
                NSLog("WARN:::Cannot delete existing file: \(finalFilename), error: \(error.debugDescription)")
            }
        } else {
            NSLog("DEBUG:::The file \(finalFilename) doesn't exist")
        }
        
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            self.videoURL = destinationURL
        } catch {
            print("Cannot copy item at \(sourceURL) to \(destinationURL): \(error)")
        }
    }
    
    @IBAction func tapPlayVideo(_ sender: UIButton) {
        loadData()
        guard let videoURL = videoURL else { return }
        let player = AVPlayer(url: videoURL)
        let playerController = AVPlayerViewController()
        playerController.player = player
        self.present(playerController, animated: true) {
            player.play()
        }
        
    }
}
