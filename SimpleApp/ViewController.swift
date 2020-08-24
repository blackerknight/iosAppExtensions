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

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        let sharedContainerURL: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.blacker.extension")
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
