//
//  TodayViewController.swift
//  SimpleAppExtension
//
//  Created by eduardo mancilla on 19/08/20.
//  Copyright © 2020 eduardo mancilla. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet weak var extensionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
         let groupDefaults = UserDefaults(suiteName: "group.com.blacker.extension")
            
         if let extensionText = groupDefaults?.value(forKey: "extensionText") as? String {
              extensionLabel.text = extensionText
         }
            
         completionHandler(NCUpdateResult.newData)
    }
    
}
