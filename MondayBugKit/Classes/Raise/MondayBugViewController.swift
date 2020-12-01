//
//  MondayBugViewController.swift
//  MondayBugKit
//
//  Created by Will Powell on 02/11/2020.
//

import Eureka
import MBProgressHUD

class MondayBugViewController: FormViewController {
    
    var mondayBoard:MondayBoard?
    var options:RaiseOptions?
    
    @objc
    func dismissNow(){
        dismiss(animated: true, completion: nil)
    }
    
    @objc
    func save(){
        let data = form.values()
        print(data);
        guard let board = mondayBoard else{
            print("No Board")
            return
        }
        guard let boardId = MondayBugKit.context.boardId else{
            print("No Board Id")
            return
        }
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        MondayAPI.createItem(boardId: boardId, data: data, columns: board.columns) { (success) in
            DispatchQueue.main.async { [weak self] in
                hud.hide(animated: true)
                self?.dismissNow()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup navigation Item
        self.navigationItem.title = options?.viewControllerTitle ?? ""
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissNow))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        
        let section = Section()
        guard let board = mondayBoard else {
            return
        }
        board.columns?.forEach({ (column) in
            let name = column.title
            let type = column.type
            let id = column.id ?? ""
            let idStr = "\(id)"
            switch(type){
            case "name":
                section <<< TextRow(idStr){ row in
                    row.title = name
                    row.placeholder = "Enter text here"
                }
                break
            case "text":
                section <<< TextAreaRow(idStr) {
                    $0.title = "\(name)"
                    $0.placeholder = "\(name)"
                    $0.textAreaHeight = .dynamic(initialTextViewHeight: 50)
                }
                break
            case "long-text":
                section <<< TextAreaRow(idStr) {
                    $0.title = "\(name)"
                    $0.placeholder = "\(name)"
                    $0.textAreaHeight = .dynamic(initialTextViewHeight: 50)
                }
                break
            /*case "multiple-person":
                section <<< PushRow<String>(idStr) {
                    $0.title = "\(name)"
                    //$0.value = type
                    $0.selectorTitle = "\(name)"
                    $0.optionsProvider = .lazy({ (form, completion) in
                        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
                        form.tableView.backgroundView = activityView
                        activityView.startAnimating()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                            form.tableView.backgroundView = nil
                            completion(["1", "2"])
                        })
                    })
                    }
                break;*/
            case "color":
                section <<< PushRow<String>(idStr) {
                    $0.title = "\(name)"
                    //$0.value = type
                    $0.selectorTitle = "\(name)"
                    $0.optionsProvider = .lazy({ (form, completion) in
                        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
                        form.tableView.backgroundView = activityView
                        activityView.startAnimating()
                        let settings_str = column.settings_str
                        
                        var items = [String]()
                        if let settings_data = settings_str.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: settings_data, options: .mutableContainers) as? [String: Any] {
                            if let labels = json?["labels"] as? [String:Any]{
                                labels.forEach { (key, value) in
                                    if let strValue = value as? String {
                                        items.append(strValue)
                                    }
                                }
                            }
                        }
                        DispatchQueue.main.async {
                            form.tableView.backgroundView = nil
                            completion(items)
                        }
                    })
                }
                break;
            case "timerange":
                /*section <<< LabelRow () {
                    $0.title = "timerange"
                    }*/
                break;
            case "file":
                /*section <<< LabelRow () {
                    $0.title = "file"
                }*/
                break;
            case "date":
                section <<< DateRow(idStr) { $0.value = Date(); $0.title = name }
            default:
                /*section <<< LabelRow () {
                    $0.title = "\(name) \(type)"
                    }*/
                break;
            }
            
        })
        form +++ section
            
        /*    <<< PhoneRow(){
                $0.title = "Phone Row"
                $0.placeholder = "And numbers here"
            }
        +++ Section("Section2")
            <<< DateRow(){
                $0.title = "Date Row"
                $0.value = Date(timeIntervalSinceReferenceDate: 0)
            }*/
    }
}
