//
//  TouchHandler.swift
//  RemoteLogTest
//


import UIKit

internal class TouchHandler {
    
    static var currentFocusEvent:UIRemoteEvent?
    
    
    static func generateXPath(_ responder:UIView)->String?{
        guard let xpath = iterateXPath(responder, [String]())?.reversed().joined(separator: "/") else {
            return nil
        }
        //print("/\(xpath)")
        return "//\(xpath)"
    }
    
    static func iterateXPath(_ view:UIView, _ currentString:[String])->[String]?{
        var className = NSStringFromClass(type(of: view))
        var currentStrings = currentString
        
        if let accessibilityIdentifier = view.accessibilityIdentifier {
            className += "[@name=\"\(accessibilityIdentifier)\"]"
            currentStrings.append(className)
            return currentStrings
        }
        
        guard let parentView = view.superview else {
            currentStrings.append(className)
            return currentStrings
        }
        let subViews = parentView.subviews
        
        if subViews.count > 1, let index = subViews.firstIndex(of: view){
            let controls = subViews.filter{ (view) -> Bool in
                return view is UIControl
            }
            let targetCount:Int = controls.count - Int(index)
            className += "[\(targetCount)]"
        }
        currentStrings.append(className)
        
        return iterateXPath(parentView, currentStrings)
    }
    
    static func process(touch:UITouch){
        if let responder = touch.view {
            var output = "TOUCH"
            let classString =  NSStringFromClass(type(of: responder))
            let permittedClasses = ["_UIAlertControllerActionView", "UITextField", "_UIButtonBarButton","UITableViewCellContentView"]
            let remote = UIRemoteEvent()
            remote.xpath = generateXPath(responder)
            remote.accessibilityIdentifierValue = responder.accessibilityIdentifier
             if let control = responder as? UIControl {
                let events:UIControl.Event = control.allControlEvents
                var touchEvent:UIControl.Event? = nil
                var actionDetails = ""
                switch touch.phase{
                case UITouch.Phase.began:
                    touchEvent = UIControl.Event.touchDown
                    actionDetails = "touch down"
                    break;
                case UITouch.Phase.ended:
                    touchEvent = UIControl.Event.touchUpInside
                    actionDetails = "touch up"
                    break;
                default:
                    return
                }
                if permittedClasses.contains(classString), touch.phase == .ended {
                    remote.subType = "TouchEvent_OVERRIDE"
                }else if let touchEvt = touchEvent, events == touchEvt {
                    remote.subType = "TouchEvent"
                }else if let touchEvt = touchEvent, touchEvt == .touchUpInside {
                    remote.subType = "TouchEvent"
                }else{
                    return
                }
                
                output = "User \(actionDetails)"
                if let button = control as? UIButton {
                    let buttonTitle = button.titleLabel?.text ?? ""
                    output = "User \(actionDetails) on \(buttonTitle) button"
                }
                
             }else if permittedClasses.contains(classString), touch.phase == .ended {
                remote.subType = "TouchEvent_OVERRIDE"
             }else{
                return
            }
            remote.accessibilityLabel = responder.accessibilityLabel
            remote.type = RemoteEventType.ui
            
            remote.className = classString
            
            
            if let parentView = responder.superview {
                if let tableViewCell = parentView as? UITableViewCell {
                    if let tableView = tableViewCell.superview as? UITableView, let indexPath = tableView.indexPath(for: tableViewCell) {
                        
                        remote.indexRow = indexPath.row
                        remote.indexSection = indexPath.section
                        var globalIndex = 0
                        if indexPath.section > 0 {
                            for i in 0..<indexPath.section {
                                globalIndex = globalIndex + tableView.numberOfRows(inSection: i)
                            }
                        }
                        globalIndex += indexPath.row
                        output = "Touch Table Cell (\(indexPath.section),\(indexPath.row)) global:\(globalIndex)"
                        remote.indexGlobal = globalIndex
                    }
                }else if let collectionViewCell = parentView as? UICollectionViewCell {
                    if let collectionView = collectionViewCell.superview as? UICollectionView, let indexPath = collectionView.indexPath(for: collectionViewCell) {
                        remote.indexRow = indexPath.row
                        remote.indexSection = indexPath.section
                        var globalIndex = 0
                        if indexPath.section > 0 {
                            for i in 0..<indexPath.section {
                                globalIndex = globalIndex + collectionView.numberOfItems(inSection: i)
                            }
                        }
                        globalIndex += indexPath.row
                        remote.indexGlobal = globalIndex
                        output = "Touch Collection Cell (\(indexPath.section),\(indexPath.row)) global:\(globalIndex)"
                    }
                }
            }
            remote.details = output
            currentFocusEvent = remote
            touchWithScreenShot(touch: touch, event: remote)
        }
    }
    
    static func touchWithScreenShot(touch:UITouch, event:UIRemoteEvent){
        let app = UIApplication.shared
        let window = app.keyWindow
        guard let viewcontroller = window?.rootViewController else {
            return
        }
        let location = touch.location(in: viewcontroller.view)
        event.touchX = Float(location.x)
        event.touchY = Float(location.y)
        if let touchView = touch.view, let targetPoint = touchView.superview?.convert(touchView.frame.origin, to: nil) {
            event.targetX = Float(targetPoint.x)
            event.targetY = Float(targetPoint.y)
            event.targetWidth = Float(touchView.frame.width)
            event.targetHeight = Float(touchView.frame.height)
        }
        
        if RemoteLog.viewControllerAppearSnapshot == true {
            if Thread.isMainThread{
                if let image = window?.capture() {
                    event.image = image//ImageUtils.resizeImage(image:image, maxDimension:512)
                }
                RemoteLog.context.send(event)
            }else{
                DispatchQueue.main.async {
                    if let image = window?.capture() {
                        event.image = image//ImageUtils.resizeImage(image:image, maxDimension:512)
                    }
                    RemoteLog.context.send(event)
                }
            }
        }else{
            RemoteLog.context.send(event)
        }
    }
}


