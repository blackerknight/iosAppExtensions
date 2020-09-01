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
import FirebaseCrashlytics
import FirebaseAnalytics

class ViewController: UIViewController {
    private let videoName: String = "videoRecordScreen.mp4"
    private var videoURL: URL?
    private var portal: BBPortalProtocol!
    @IBOutlet weak var labelStatus: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        // Ask for Notification Permissions
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.sound, .alert, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    // Handle error or not granted scenario
                }
            }
        }
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
        
        portal.onDataAvailable = { [weak self] data in
            guard let self = self else { return }
            guard let dict = data as? [String: Any?] else { return }
            let status = dict[Shared.Constantes.Key.status] as! String
            DispatchQueue.main.async {
                switch status {
                case "finish":
                    self.labelStatus.text = "Se termino de grabar la pantalla. \n Video guardado"
                case "start":
                    self.labelStatus.text = "Grabando la pantalla..."
                default:
                    print("etiqueta fuera del switch: \(status)")
                }
            }
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
    
    @IBAction func tapSendnotification(_ sender: UIButton) {
        scheduleGroupedNotifications()
    }
    
    @IBAction func tapDeletenotification(_ sender: UIButton) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in
           var identifiers: [String] = []
           for notification:UNNotificationRequest in notificationRequests {
               if notification.identifier == "1FiveSecond" {
                  identifiers.append(notification.identifier)
               }
           }
           UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    @IBAction func tapForceCrash(_ sender: UIButton) {
        Crashlytics.crashlytics().setUserID("123456789")
        
        // Set int_key to 100.
        Crashlytics.crashlytics().setCustomValue(100, forKey: "int_key")

        // Set str_key to "hello".
        Crashlytics.crashlytics().setCustomValue("hello", forKey: "str_key")
        
        //You can record non-fatal exceptions by recording NSError
        Crashlytics.crashlytics().record(error: NSError(domain: "error domain", code: 0, userInfo: ["key": "value"]))
        
        
        
        let userInfo = [
          NSLocalizedDescriptionKey: NSLocalizedString("The request failed.", comment: ""),
          NSLocalizedFailureReasonErrorKey: NSLocalizedString("The response returned a 404.", comment: ""),
          NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Does this page exist?", comment: ""),
          "ProductID": "123456",
          "View": "MainView"
        ]

        let error = NSError.init(domain: NSCocoaErrorDomain,
                                 code: -1001,
                                 userInfo: userInfo)
        
        
        Analytics.logEvent("button_Crash", parameters: [
        "name": "test" as NSObject,
        "full_text": "abcdefghi" as NSObject
        ])
        
        Crashlytics.crashlytics().record(error: error)
        
        
        fatalError()
    }

    func scheduleGroupedNotifications() {
        for i in 1...6 {
            let notificationContent = UNMutableNotificationContent()
            notificationContent.title = "Hello!"
            notificationContent.body = "Do not forget the pizza!"
            notificationContent.sound = UNNotificationSound.default

            if i % 2 == 0 {
                notificationContent.threadIdentifier = "Guerrix-Wife"
                if #available(iOS 12.0, *) {
                    notificationContent.summaryArgument = "your wife"
                }
            } else {
                notificationContent.threadIdentifier = "Guerrix-Son"
                if #available(iOS 12.0, *) {
                    notificationContent.summaryArgument = "your son"
                }
            }

            // Deliver the notification in five seconds.
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            // Schedule the notification.
            let request = UNNotificationRequest(identifier: "\(i)FiveSecond", content: notificationContent, trigger: trigger)
            let center = UNUserNotificationCenter.current()
            center.add(request) { (error: Error?) in
                if let theError = error {
                    print(theError)
                }
            }
        }
    }
}
