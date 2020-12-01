//
//  UIViewController+RemoteLog.swift
//  RemoteLogTest
//

import UIKit

private let swizzling: (UIViewController.Type) -> () = { viewController in
    
    let originalSelector = #selector(viewController.viewDidAppear(_:))
    let swizzledSelector = #selector(viewController.proj_viewDidAppear(animated:))
    
    guard let originalMethod = class_getInstanceMethod(viewController, originalSelector) else {
        return
    }
    guard let swizzledMethod = class_getInstanceMethod(viewController, swizzledSelector) else {
        return
    }
    method_exchangeImplementations(originalMethod, swizzledMethod)
}

extension UIViewController {
    
    static func remoteLog(){
        guard self === UIViewController.self else { return }
        swizzling(self)
    }
    
    static let ignoredViewControllerClasses = ["UIInputWindowController"]
    
    // MARK: - Method Swizzling
    
    @objc
    func proj_viewDidAppear(animated: Bool) {
        if RemoteLog.context.isEnabled {
            let className = NSStringFromClass(type(of: self))
            var shouldCaptureEvent = !UIViewController.ignoredViewControllerClasses.contains(className)
            if self is UINavigationController {
                shouldCaptureEvent = false
            }
            if self is UITabBarController {
                shouldCaptureEvent = false
            }
            if shouldCaptureEvent {
                let event = UIRemoteEvent()
                event.className = className
                event.subType = "ViewDidAppear"
                event.type = RemoteEventType.ui
                var detailMessage = "Unknown view appear"
                if let eventClassName = event.className {
                    detailMessage = "\(eventClassName) view appear"
                }
                event.details = detailMessage
                if RemoteLog.viewControllerAppearSnapshot == true {
                    if RemoteLog.viewControllerAppearExempt.contains(className) {
                        RemoteLog.context.send(event)
                    }else{
                        DispatchQueue.main.async {
                            let app = UIApplication.shared
                            let window = app.keyWindow
                            if let image = window?.capture() {
                                event.image = image
                            }
                            RemoteLog.context.send(event)
                        }
                    }
                }else{
                    RemoteLog.context.send(event)
                }
                
            }
        }
        self.proj_viewDidAppear(animated: animated)
    }
}
