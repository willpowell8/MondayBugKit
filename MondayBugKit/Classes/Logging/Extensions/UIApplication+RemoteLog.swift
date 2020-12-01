//
//  UIApplication+RemoteLog.swift
//  RemoteLogTest
//

import UIKit
private let swizzling: (UIApplication.Type) -> () = { application in
    
    let originalSelector = #selector(application.sendEvent(_:))
    let swizzledSelector = #selector(application.monitor_sendEvent(_:))
    
    guard let originalMethod = class_getInstanceMethod(application, originalSelector) else{
        return
    }
    guard let swizzledMethod = class_getInstanceMethod(application, swizzledSelector) else {
        return
    }
    
    method_exchangeImplementations(originalMethod, swizzledMethod)
}

extension UIApplication {
    
    static func remoteLog(){
        guard self === UIApplication.self else { return }
        swizzling(self)
    }
    
    // MARK: - Method Swizzling
    @objc
    func monitor_sendEvent(_ event: UIEvent) {
        if RemoteLog.context.isEnabled {
            event.allTouches?.forEach({ (touch) in
                TouchHandler.process(touch: touch)
            })
        }
        self.monitor_sendEvent(event)
    }
}
