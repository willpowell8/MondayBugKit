//
//  RemoteLog.swift
//


import Foundation
import UIKit
import Zip

public struct RemoteNetworkProfile{
    public let connectionType:String?
    public var requests = [(date:Date, speed:Float)]()
}

public class RemoteLog:NSObject{
    
    public static let context = RemoteLog()
    public static let notify = Notification.Name("REMOTE_LOG_NOTIFY")
    
    public let networkEmulator = URLEmulator()
    public static var viewControllerAppearSnapshot:Bool = true
    public static var viewControllerAppearExempt = [String]()
    
    public var maxAllEventBuffer:Int = 20
    public var maxUIEventBuffer:Int = 10
    
    private var uiEventBuffer = [UIRemoteEvent]()
    private var allEventBuffer = [RemoteEvent]()
    
    
    fileprivate var reachability:Reachability?
    fileprivate var _profilingNetwork:Bool = true
    
    fileprivate var performanceByNetwork = [String:RemoteNetworkProfile]()
    
    public var isEnabled:Bool = true
    public var isNotificationHandlerEnabled:Bool = true
    public var profileNetworkResponseSizeThreshold:Float = 0.1
    
    public var profilingNetwork:Bool {
        get{
            return _profilingNetwork
        }
        set{
            if newValue != _profilingNetwork {
                if newValue == true, reachability == nil {
                    reachability = Reachability()
                }
                _profilingNetwork = newValue
            }
        }
    }
    
    
    private var transmitters = [Transmit]()
    private var pendingEvent:RemoteEvent? {
        didSet{
            if pendingEvent != nil {
                timer?.invalidate()
                if #available(iOS 10.0, *) {
                    // use the feature only ava
                    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { (timer) in
                        self.sendPendingEvent()
                    })
                }
            }
        }
    }
    private var timer:Timer?
    
    func sendPendingEvent(){
        guard let p = self.pendingEvent else {
            return
        }
        completeSend(p)
        self.pendingEvent = nil
        timer?.invalidate()
    }
    
    func send(_ event:RemoteEvent){
        sendPendingEvent()
        timer?.invalidate()
        completeSend(event)
    }
    
    func completeSend(_ event:RemoteEvent){
        guard isEnabled else {
            return
        }
        transmitters.forEach { (transmit) in
            transmit.sendEvent(event)
        }
        
        // Add event to all event buffer
        allEventBuffer.insert(event, at: 0)
        if allEventBuffer.count > maxAllEventBuffer {
            allEventBuffer.remove(at: allEventBuffer.count-1)
        }
        
        // add ui event to ui event
        if let uiEvent = event as? UIRemoteEvent {
            uiEventBuffer.insert(uiEvent, at: 0)
            if uiEventBuffer.count > maxUIEventBuffer {
                uiEventBuffer.remove(at: uiEventBuffer.count-1)
            }
        }
    }
    
    public func exportZip(){
        let documentsDirectory = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)[0]
        let zipFilePath = documentsDirectory.appendingPathComponent("archive.zip")
        print(zipFilePath)
        var logObject = [String:Any]()
        logObject["source"] = "iOS_SDK"
        logObject["device"] = DeviceInfo.details
        var files = [ArchiveFile]();
        if let icon = Bundle.main.icon {
            let imageData = UIImageJPEGRepresentation(icon, 0.75)
            files.append(ArchiveFile(filename: "icon.jpg", data: imageData as! NSData, modifiedTime: Date()))
        }
        
        var count = 1
        
        
        var screenshots = [[String:Any]]()
        uiEventBuffer.reversed().forEach({ (event) in
            guard let image = event.getTouchImage() else {
                return
            }
            let imageData = UIImageJPEGRepresentation(image, 0.75)
            files.append(ArchiveFile(filename: "img\(count).jpg", data: imageData as! NSData, modifiedTime: Date()))

            var record = event.export()
            record["file"] = "img\(count).jpg"
            screenshots.append(record)
            count += 1
        })
        logObject["screens"] = screenshots
        
        
        var allEvents = [[String:Any]]()
        allEventBuffer.forEach { (event) in
            allEvents.append(event.export())
        }
        logObject["events"] = allEvents
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: logObject, options: .fragmentsAllowed) {
            let arc = ArchiveFile(filename: "log.json", data: jsonData as NSData, modifiedTime: Date())
            files.append(arc)
            try? Zip.zipData(archiveFiles: files, zipFilePath: zipFilePath, password: nil, progress: { (p) in
                print("percentage \(p)")
            })
        }
    }
    
    public func exportTechPDF(_ additionalInfo:[String:String]?, completion:@escaping(String?)->Void) {
        let A4paperSize = CGSize(width: 595, height: 842)
        let pdf = SimplePDF(pageSize: A4paperSize)
        let deviceInfo = DeviceInfo.details
        var deviceStringAry = [[String]]()
        deviceInfo.forEach { (item) in
            deviceStringAry.append([item.key, item.value])
        }
        pdf.addText("System Details")
        pdf.addTable(deviceInfo.count, columnCount: 2, rowHeight: 20.0, columnWidth: 200.0, tableLineWidth: 1.0, font: UIFont.systemFont(ofSize: 10.0), dataArray: deviceStringAry)
        pdf.addLineSpace(20.0)
        if let additionalData = additionalInfo {
            pdf.addText("Additional Information")
            var additionalAry = [[String]]()
            additionalData.forEach { (item) in
                additionalAry.append([item.key, item.value])
            }
            pdf.addTable(additionalAry.count, columnCount: 2, rowHeight: 20.0, columnWidth: 200.0, tableLineWidth: 1.0, font: UIFont.systemFont(ofSize: 10.0), dataArray: additionalAry)
            pdf.addLineSpace(20.0)
        }
        
        pdf.beginNewPage()
        pdf.addText("Events")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
        
        let attribute: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 5, weight: UIFont.Weight.thin),
                                         NSAttributedString.Key.foregroundColor: UIColor.black]
        
        allEventBuffer.forEach { (event) in
            var elements = [String]()
            if let date = event.date {
                elements.append(dateFormatter.string(from: date))
            }else{
                elements.append("?")
            }
            elements.append(event.type?.rawValue ?? "?")
            if let uiEvent = event as? UIRemoteEvent {
                elements.append(uiEvent.details ?? "?")
                elements.append(uiEvent.subType ?? "?")
            }else if let networkEvent = event as? NetworkRemoteEvent {
                elements.append("Code: \(networkEvent.responseStatusCode)")
                var details = ""
                if let duration = networkEvent.duration {
                    let roundedDuration = round(duration*1000)/1000
                    details += "Duration: \(roundedDuration)"
                }
                elements.append(details)
            }else if event is ConsoleRemoteLog {
                elements.append("")
                elements.append("")
            }else{
                elements.append("?")
                elements.append("?")
            }
            var fields = [[String]]()
            fields.append(elements)
            pdf.addTable(fields.count, columnCount: 4, rowHeight: 12.0, columnWidth: 140.0, tableLineWidth: 1.0, font: UIFont.systemFont(ofSize: 5.0), dataArray: fields)
            
            if let uiEvent = event as? UIRemoteEvent {
                // todo add uiEvent add to PDF
            }else if let networkEvent = event as? NetworkRemoteEvent {
                pdf.addLineSpace(10)
                let attributedText1 = NSAttributedString(string: "REQUEST", attributes: attribute)
                pdf.addAttributedText(attributedText1)
                if let url = networkEvent.requestURLString {
                    let attributedText = NSAttributedString(string: "url: \(url)", attributes: attribute)
                    pdf.addAttributedText(attributedText)
                }
                
                if let method = networkEvent.requestHTTPMethod {
                    let attributedText = NSAttributedString(string: "method: \(method)", attributes: attribute)
                    pdf.addAttributedText(attributedText)
                }
                
                if let timeout = networkEvent.requestTimeoutInterval {
                    let attributedText = NSAttributedString(string: "Timeout: \(timeout)", attributes: attribute)
                    pdf.addAttributedText(attributedText)
                }
                
                if let cachePolicy = networkEvent.requestCachePolicy {
                    let attributedText = NSAttributedString(string: "Cache Policy: \(cachePolicy)", attributes: attribute)
                    pdf.addAttributedText(attributedText)
                }
                
                if let body = networkEvent.requestHTTPBody {
                    let attributedText = NSAttributedString(string: body, attributes: attribute)
                    pdf.addAttributedText(attributedText)
                }
                pdf.addLineSpace(10)
                
                
                let attributedText2 = NSAttributedString(string: "RESPONSE", attributes: attribute)
                pdf.addAttributedText(attributedText2)
                if let headers = networkEvent.responseAllHeaderFields {
                    let attributedText = NSAttributedString(string: headers, attributes: attribute)
                    pdf.addAttributedText(attributedText)
                }
                
                if let responseLength = networkEvent.responseExpectedLength {
                    let attributedText = NSAttributedString(string: "Response Length: \(responseLength)", attributes: attribute)
                    pdf.addAttributedText(attributedText)
                }
                
                if let mimeType = networkEvent.responseMIMEType {
                    let attributedText = NSAttributedString(string: "Mime Type: \(mimeType)", attributes: attribute)
                    pdf.addAttributedText(attributedText)
                }
                
                if let receivedDataString = networkEvent.receiveDataString {
                    let attributedText = NSAttributedString(string: receivedDataString, attributes: attribute)
                    pdf.addAttributedText(attributedText)
                }
                
                pdf.addLineSpace(10)
                
            }else if let consoleEvent = event as? ConsoleRemoteLog{
                if let body = consoleEvent.body {
                    let attributedText = NSAttributedString(string: body, attributes: attribute)
                    pdf.addAttributedText(attributedText)
                }
            }
        }
        
        
        
        let pdfData = pdf.generatePDFdata()
        let fileName = "techReport.pdf"
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(fileName)
            
            //writing
            do {
                try pdfData.write(to: fileURL, options: .atomic)
                completion(fileURL.absoluteString)
                return
            }
            catch {
                /* error handling here */
                
            }
        }
        
        
        completion(nil)
        
    }
    
    public func exportTDDTest(featureName:String?, scenarioName:String?, completion:@escaping (_ test:String?,_ additionalData:String?)->Void){
        var test = [String]()
        let feature = featureName ?? ""
        let scenario = scenarioName ?? ""
        test.append("Feature: \(feature)")
        test.append("")
        test.append("Scenario: \(scenario)")
        var additionalData = [String]()
        
        self.allEventBuffer.reversed().forEach { (event) in
            if event is UIRemoteEvent {
                test.append(contentsOf: event.tdd())
            }else if event is NetworkRemoteEvent {
                additionalData.append(contentsOf: event.tdd())
            }
        }
        
        let testString = test.joined(separator: "\n")
        let additionalDataString = additionalData.joined(separator: "\n")
        completion(testString, additionalDataString)
    }
    
    public func exportUIBufferPDF(_ completion: @escaping (String?) -> Void, excludeLastXEvents:Int = 0) -> Void{
        let uiEventBuffer = self.uiEventBuffer
        let endCount = uiEventBuffer.count - excludeLastXEvents
        guard endCount > 0 else {
            completion(nil)
            return
        }
        DispatchQueue.global(qos: .background).async {
            let fileName = "uibuffer.pdf"
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory = paths[0] as NSString
            let pathForPDF = documentsDirectory.appending("/" + fileName)
            
            UIGraphicsBeginPDFContextToFile(pathForPDF, .zero, nil)
            uiEventBuffer.reversed().forEach({ (event) in
                guard let image = event.getTouchImage() else {
                    return
                }
                let imageSize = CGRect(x:0,y:0,width:image.size.width,height:image.size.height)
                let pageSize = CGRect(x:0,y:0,width:image.size.width,height:image.size.height+40)
                UIGraphicsBeginPDFPageWithInfo(pageSize, nil)
                
                image.draw(in: imageSize, blendMode: .normal, alpha: 1.0)
                let font = UIFont(name: "Helvetica", size: 12.0)
                
                let textRect = CGRect(x:5,y:image.size.height+5,width:image.size.width,height:18)
                let paragraphStyle:NSMutableParagraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                paragraphStyle.alignment = NSTextAlignment.left
                paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
                
                let textColor = UIColor.black
                
                let textFontAttributes = [
                    NSAttributedString.Key.font: font!,
                    NSAttributedString.Key.foregroundColor: textColor,
                    NSAttributedString.Key.paragraphStyle: paragraphStyle
                ]
                
                let text = "UI Action:\(event.details!)"
                text.draw(in: textRect, withAttributes: textFontAttributes)
            })
            UIGraphicsEndPDFContext()
            completion(pathForPDF)
        }
    }
    
    public func exportUIBufferGIF(_ completion: @escaping (String?) -> Void, excludeLastXEvents:Int = 0) -> Void{
        let uiEventBuffer = self.uiEventBuffer
        let endCount = uiEventBuffer.count - excludeLastXEvents
        guard endCount > 0 else {
            completion(nil)
            return
        }
        DispatchQueue.global(qos: .background).async {
            let images = uiEventBuffer.reversed().compactMap({ (event) -> UIImage? in
                return event.getTouchImage()
            })
            if let gifPath = ImageUtils.generateGif(photos: images, filename: "uibuffer.gif") {
                completion(gifPath)
                return
            }
            completion(nil)
        }
    }
    
    public func addTransmitter( transmitter:Transmit){
        transmitter.start();
        self.transmitters.append(transmitter)
    }
    
    public func setup(){
        NetworkEye.add(observer: self)
    }
    
    public func getNetworkProfileStats()->[String:RemoteNetworkProfile]{
        return performanceByNetwork
    }
    
    public func resetNetworkProfileStats(){
        performanceByNetwork = [String:RemoteNetworkProfile]()
    }
    
    override init() {
        super.init()
        UIApplication.remoteLog()
        UIViewController.remoteLog()
        URLSessionConfiguration.remoteLog()
        //UIControl.remoteLog()
        NotificationCenter.default.addObserver(self, selector: #selector(notificationSend(_:)), name: RemoteLog.notify, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidChange(_:) ), name:
                                                NSNotification.Name.UITextFieldTextDidChange,
                                       object: nil)
    }
    
    @objc
    func textFieldDidChange(_ sender:Any?){
        if let notification = sender as? Notification, let obj = notification.object {
            
            if let textField = obj as? UITextField, textField.isFirstResponder {
                let event = UIRemoteEvent()
                event.subType = "KeyboardEnter"
                if let anyClass = type(of:obj) as? AnyClass {
                    event.className = NSStringFromClass(anyClass)
                }
                if let textFieldAID = textField.accessibilityIdentifier  {
                    event.accessibilityIdentifierValue = textField.accessibilityIdentifier
                    if let text = textField.text, !text.isEmpty {
                        event.details = "Typed into '\(textFieldAID)' value '\(text)'"
                        event.additionalData["text"] = text
                    }else{
                        event.details = "Cleared text in '\(textFieldAID)' "
                    }
                    pendingEvent = event
                }else if let className = event.className, UIRemoteEvent.permittableTypeClassNames.contains(className){
                    if let text = textField.text, !text.isEmpty {
                        event.details = "Typed into class '\(className)' value '\(text)'"
                        event.additionalData["text"] = text
                    }else{
                        event.details = "Cleared text in class '\(className)' "
                    }
                    pendingEvent = event
                }
                
            }
        }
    }
    
    @objc
    public func notificationSend(_ notification:Notification){
        guard isNotificationHandlerEnabled == true, let userInfo = notification.userInfo, let event = userInfo["event"] as? RemoteEvent else {
            return
        }
        RemoteLog.context.send(event)
    }
    
    deinit {
        
    }
    
}

extension RemoteLog:NetworkEyeDelegate{
    public func networkEyeDidCatch(with request:URLRequest?,response:URLResponse?,data:Data?, duration:TimeInterval?){
        let network = NetworkRemoteEvent()
        network.initialize(request: request)
        if let httpResponse = response as? HTTPURLResponse {
            network.initialize(response: httpResponse, data: data)
        }
        
        if let dur = duration {
            network.duration = -Double(dur)
            if let responseExpectedLength = network.responseExpectedLength, responseExpectedLength > profileNetworkResponseSizeThreshold {
                let speed = -responseExpectedLength/Float(dur)
                if _profilingNetwork, let reachability = self.reachability {
                    let networkType = reachability.connection
                    if performanceByNetwork[networkType.description] == nil {
                        performanceByNetwork[networkType.description] = RemoteNetworkProfile(connectionType: networkType.description, requests: [(date: Date(), speed: speed)])
                    }else{
                        performanceByNetwork[networkType.description]?.requests.append((date: Date(), speed: speed))
                    }
                }
            }
        }
        RemoteLog.context.send(network)
    }
}

extension Bundle {
    public var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}
