//
//  UIControl+RemoteLog.swift
//  RemoteLogTest
//

import UIKit

/*private let swizzling: (UIControl.Type) -> () = { control in
    
    let originalSelector = #selector(UIView.init(frame:))
    let swizzledSelector = #selector(control.proj_init(frame:))
    
    guard let originalMethod = class_getInstanceMethod(control, originalSelector) else {
        return
    }
    guard let swizzledMethod = class_getInstanceMethod(control, swizzledSelector) else {
        return
    }
    
    method_exchangeImplementations(originalMethod, swizzledMethod)
    
}

extension UIControl {
    static func remoteLog(){
        guard self === UIControl.self else { return }
        swizzling(self)
    }
    
    // MARK: - Method Swizzling
    @objc
    func proj_init(frame: CGRect){
        print("CONTROL INIT FRAME")
        self.proj_init(frame: frame)
    }
    
    
    @objc
    func proj_init(coder aDecoder: NSCoder){
        print("CONTROL INIT")
        self.proj_init(coder: aDecoder)
    }
    
    @objc
    func proj_init2(coder aDecoder: NSCoder){
        print("CONTROL INIT")
        self.proj_init(coder: aDecoder)
    }
}*/
