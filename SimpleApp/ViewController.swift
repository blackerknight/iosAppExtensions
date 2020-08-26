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
import BBPortal

class ViewController: UIViewController {
    private let videoName: String = "videoRecordScreen.mp4"
    private var videoURL: URL?
    private var portal: BBPortalProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        let groupDefaults = UserDefaults(suiteName: Shared.Constantes.groupName)
        
        groupDefaults?.set("A text", forKey: "extensionText")
        
        if #available(iOS 12.0, *) {
            groupDefaults?.set(videoName, forKey: Shared.Constantes.Key.videoName)
            
            let broadCastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 100, y: 200, width: 160, height: 150))
            broadCastPicker.preferredExtension = Shared.Constantes.preferredExtension
            self.view.addSubview(broadCastPicker)
        } else {
            // no podemos inicial la captura de pantalla en versiones menores a ios 12
        }
        loadData()
        startPortal()
    }
    
    private func loadData() {
        let sharedContainerURL: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Shared.Constantes.groupName)
        let filePath: String = "\(Shared.Constantes.Names.folderShared)/\(videoName)"
        guard let sourceURL: URL = sharedContainerURL?.appendingPathComponent(filePath) else { return }
        
        guard let destinationURL: URL = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(videoName) else { return }
        
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
    
    private func startPortal() {
        portal = BBPortal(withGroupIdentifier: Shared.Constantes.groupName, andPortalID: Shared.Constantes.portalName)
        portal.onDataAvailable = { (data) in
            guard let dict = data as? [String: Any?] else { return }
            let status = dict["key"] as! String
            print("I received some data through the portal: ", status)
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
