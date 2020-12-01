//
//  UIRemoteEvent.swift
//  RemoteLogTest
//


import Foundation
import UIKit

public class UIRemoteEvent:RemoteEvent{
    public var id = Date().timeIntervalSince1970
    public var subType:String?
    
    public var touchX:Float?
    public var touchY:Float?
    public var targetX:Float?
    public var targetY:Float?
    public var targetWidth:Float?
    public var targetHeight:Float?
    public var image:UIImage?
    
    public var className:String?
    
    public var xpath:String?
    
    public var indexGlobal:Int?
    public var indexRow:Int?
    public var indexSection:Int?
    
    public var accessibilityLabelValue:String?
    public var accessibilityIdentifierValue:String?
    
    public var parentClassName:String?
    public var parentAccessibilityLabelValue:String?
    public var parentAccessibilityIdentifierValue:String?
    
    public var additionalData = [String:Any]()
    
    override func export()->[String:Any]{
        var exportVal = super.export()
        exportVal["subType"] = self.subType
        if let touchX = self.touchX { exportVal["touchX"] = touchX }
        if let touchY = self.touchY { exportVal["touchY"] = touchY }
        if let targetX = self.targetX { exportVal["targetX"] = targetX }
        if let targetY = self.targetY { exportVal["targetY"] = targetY }
        if let targetWidth = self.targetWidth { exportVal["targetWidth"] = targetWidth }
        if let targetHeight = self.targetHeight { exportVal["targetHeight"] = targetHeight }
        if let accessibilityLabel = self.accessibilityLabelValue { exportVal["accessibilityLabel"] = accessibilityLabel }
        if let accessibilityIdentifier = self.accessibilityIdentifierValue { exportVal["accessibilityIdentifier"] = accessibilityIdentifier }
        if let accessibilityLabel = self.accessibilityLabelValue { exportVal["accessibilityLabel"] = accessibilityLabel }
        if let className = self.className { exportVal["className"] = className }
        
        if let indexRow = self.indexRow { exportVal["indexRow"] = indexRow }
        if let indexSection = self.indexSection { exportVal["indexSection"] = indexSection }
        if let indexGlobal = self.indexGlobal { exportVal["indexGlobal"] = indexGlobal }
        
        if let parentClassName = self.parentClassName { exportVal["parentClassName"] = parentClassName }
        if let parentAccessibilityLabelValue = self.parentAccessibilityLabelValue { exportVal["parentAccessibilityLabelValue"] = parentAccessibilityLabelValue }
        if let parentAccessibilityIdentifierValue = self.parentAccessibilityIdentifierValue { exportVal["parentAccessibilityIdentifierValue"] = parentAccessibilityIdentifierValue }
        return exportVal
    }
    
    func getTouchImage()->UIImage?{
        guard let image = self.image else {
            return nil
        }
        guard let touchXFloat = self.touchX, let touchYFloat = self.touchY else {
            return image
        }
        let touchX = Int(touchXFloat)
        let touchY = Int(touchYFloat)
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return image
        }
        image.draw(at:.zero)
        context.setFillColor(UIColor.red.cgColor)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(5)
        let crossSize = 1
        let crossDiameter = 20
        let rectangle = CGRect(x: touchX-crossDiameter, y: touchY-crossSize, width: crossDiameter*2, height: crossSize*2)
        context.addRect(rectangle)
        let rectangle2 = CGRect(x: touchX-crossSize, y: touchY-crossDiameter, width: crossSize*2, height: crossDiameter*2)
        context.addRect(rectangle2)
        context.drawPath(using: .fill)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    public static var permittableTapClassNames = ["UISearchBarTextField", "UITableViewCellContentView"]
    public static var permittableTypeClassNames = ["UISearchBarTextField"]
    func ttdTapString()->String?{
        if let accesibility = self.accessibilityIdentifierValue {
            return "When I tap on \"\(accesibility)\""
        }else if let accesibility = self.accessibilityLabel {
            let className = self.className ?? "UIButton"
            return "When I tap on \"\(className)\" with path \"\(accesibility)\""
        }
        if let className = self.className, UIRemoteEvent.permittableTapClassNames.contains(className) {
            var statement = "When I tap on class \"\(className)\""
            if let globalNumber = self.indexGlobal {
                statement += " number \(globalNumber)"
            }
            return statement
        }
        
        if let x = self.touchX, let y = self.touchY{
            return "When I tap on x,y \"\(x)\" \"\(y)\""
        }
        return nil
    }
    
    override func tdd()->[String]{
        var tddSet = [String]()
        if let subType = self.subType {
            switch(subType){
            case "TouchEvent_OVERRIDE":
                if let ttdStatement = ttdTapString() {
                    tddSet.append(ttdStatement)
                }
                break
            case "TouchEvent":
                if let ttdStatement = ttdTapString() {
                    tddSet.append(ttdStatement)
                }
                break
            case "Touch":
                if let ttdStatement = ttdTapString() {
                    tddSet.append(ttdStatement)
                }
                break
            case "KeyboardEnter":
                let text = self.additionalData["text"] as? String ?? ""
                if let access = self.accessibilityIdentifierValue {
                    tddSet.append("When I enter \"\(text)\" into \"\(access)\"")
                }else if let className = self.className {
                    tddSet.append("When I enter \"\(text)\" into class \"\(className)\"")
                }
                break
            default:
                
                break
            }
        }
        return tddSet
    }
}
