//
//  RemoteEvent.swift
//  RemoteLogTest
//


import Foundation

public enum RemoteEventType:String{
    case ui = "UI"
    case console = "console"
    case network = "network"
}

public class RemoteEvent:NSObject{
    public var title:String?
    public var type:RemoteEventType?
    public var details:String?
    public var date:Date?
    override init(){
        super.init()
        date = Date()
    }
    
    func export()->[String:Any]{
        var exportVal = [String:Any]()
        exportVal["action"] = "EVENT"
        exportVal["title"] = title
        exportVal["type"] = type?.rawValue
        exportVal["details"] = self.details
        //exportVal["class"] = type(of: self)
        if let d = date {
            exportVal["time"] = Double(d.timeIntervalSince1970)
        }
        return exportVal
    }
    
    func tdd()->[String]{
        return [String]()
    }
}
