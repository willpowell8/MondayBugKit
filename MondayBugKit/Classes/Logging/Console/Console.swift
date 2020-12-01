//
//  Console.swift
//  RemoteLogTest
//

import Foundation

public enum LogLevel:String {
    case verbose = "verbose"
}
//#if DEBUG
    
//#else
/*public func print(_ items: Any...) {
    RemoteLogConsole.log(items, level: .verbose)
    if let first = items.first {
        Swift.print(first)
    }
}*/
//#endif

class ConsoleRemoteLog:RemoteEvent {
    var body:String?
    var logLevel:LogLevel = .verbose
    var file:String?
    var line:Int?
    
    override func export() -> [String : Any] {
        var v = super.export()
        if let file = self.file { v["file"] = file}
        if let line = self.line { v["line"] = line}
        if let body = self.body { v["body"] = body}
        v["logLevel"] = logLevel.rawValue
        return v
    }
}

public class RemoteLogConsole {
    
    public static func log(_ items: Any..., level: LogLevel, file: String? = #file, function: String? = #function, line: Int? = #line){
        let stringContent = (items.first as? [Any] ?? []).reduce("") { result, next -> String in
            return "\(result)\(result.count > 0 ? " " : "")\(next)"
        }
        let consoleEvent = ConsoleRemoteLog()
        consoleEvent.type = RemoteEventType.console
        consoleEvent.body = stringContent
        consoleEvent.logLevel = .verbose
        consoleEvent.file = file
        consoleEvent.line = line
        NotificationCenter.default.post(name: RemoteLog.notify, object: nil, userInfo:["event":consoleEvent])
    }
}
