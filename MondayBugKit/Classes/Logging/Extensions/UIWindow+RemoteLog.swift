//
//  UIWindow+RemoteLog.swift
//  RemoteLogTest
//

import UIKit
extension UIWindow {
    func capture() -> UIImage? {
        let scale = UIScreen.main.scale
        guard scale > 0 else {
            return nil
        }
        guard layer.frame.width > 100, layer.frame.height > 100 else {
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale)
        guard let c = UIGraphicsGetCurrentContext() else {
            return nil
        }
        layer.render(in: c)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot
    }
}
