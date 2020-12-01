//
//  DeviceInfo.swift
//  RemoteLogTest
//


import UIKit

class DeviceInfo {
    static var details:[String:String] {
        get {
            var discoveryInfo = [String:String]()
            if let shortVersionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                discoveryInfo["version"] = shortVersionString
            }
            if let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                discoveryInfo["build"] = bundleVersion
            }
            if let bundleName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
                discoveryInfo["bundleName"] = bundleName
            }
            if let bundleName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
                discoveryInfo["bundleName"] = bundleName
            }
            if let bundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
                discoveryInfo["bundleIdentifier"] = bundleIdentifier
            }
            discoveryInfo["modelName"] = UIDevice.current.modelName
            discoveryInfo["name"] = UIDevice.current.name
            discoveryInfo["osVersion"] = UIDevice.current.systemVersion
            discoveryInfo["formFactor"] = UIDevice.current.userInterfaceIdiom == .pad ? "TABLET" : "PHONE"
            #if DEBUG
                discoveryInfo["debug"] = "Y"
            #else
                discoveryInfo["debug"] = "N"
            #endif
            return discoveryInfo
        }
    }
}
