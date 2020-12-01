//
//  URLSessionConfiguration+RemoteLog.swift
//  RemoteLogTest
//


import Foundation

private let swizzling: (URLSessionConfiguration.Type) -> () = { urlSessionConfiguration in
    
    let originalSelector = #selector(getter: urlSessionConfiguration.default)
    let swizzledSelector = #selector(getter: urlSessionConfiguration.proj_default)
    
    guard let originalMethod = class_getInstanceMethod(urlSessionConfiguration, originalSelector) else {
        return
    }
    guard let swizzledMethod = class_getInstanceMethod(urlSessionConfiguration, swizzledSelector) else {
        return
    }
    
    method_exchangeImplementations(originalMethod, swizzledMethod)
}

extension URLSessionConfiguration {
    
    static func remoteLog(){
        guard self === URLSessionConfiguration.self else { return }
        swizzling(self)
    }
    
    // MARK: - Method Swizzling
    
    @objc
    var proj_default:URLSessionConfiguration {
        get{
            return self.proj_default
        }
    }
}
