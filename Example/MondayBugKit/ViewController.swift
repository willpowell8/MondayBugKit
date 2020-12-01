//
//  ViewController.swift
//  MondayBugKit
//
//  Created by willpowell8 on 11/01/2020.
//  Copyright (c) 2020 willpowell8. All rights reserved.
//

import UIKit
import MondayBugKit

class ViewController: AbstractMondayViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction
    func raiseBug(){
        let documentsDirectory = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)[0]
        let zipFilePath = documentsDirectory.appendingPathComponent("archive.zip")
        //MondayAPI.uploadFile(itemId: "837095391", filePath: zipFilePath)
        MondayBugKit.context.raiseBug(self)
    }
    
    @IBAction func testNetworkCall(){
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configurationMonitor: configuration)
             
        guard let url = URL(string: "https://httpbin.org/headers") else {return}
        let request = NSMutableURLRequest(url: url)
        request.setValue(UUID().uuidString, forHTTPHeaderField: "UUID")
        request.setValue("\(Date().timeIntervalSinceNow)", forHTTPHeaderField: "date")
        request.httpMethod = "GET"
        let task = session.dataTask(with: request as URLRequest, completionHandler: { _, response, error in
             print("Returned")
        })
        task.resume()
    }

}

