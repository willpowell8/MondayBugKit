//
//  NetworkRemoteEvent.swift
//  RemoteLogTest
//


import Foundation

public class NetworkRemoteEvent:RemoteEvent{
    /// Request
    public var requestURLString:String?
    public var requestCachePolicy:String?
    public var requestTimeoutInterval:String?
    public var requestHTTPMethod:String?
    public var requestAllHTTPHeaderFields:String?
    public var requestHTTPBody: String?
    
    /// Response
    public var responseMIMEType: String?
    public var responseExpectedContentLength: Int64 = 0
    public var responseTextEncodingName: String?
    public var responseSuggestedFilename:String?
    public var responseStatusCode: Int = 200
    public var responseExpectedLength:Float?
    public var responseAllHeaderFields: String?
    public var receiveDataString: String?
    public var receiveData:Data?
    
    public var duration:Double?
    
    override func export()->[String:Any]{
        var exportVal = super.export()
        if let requestURLString = self.requestURLString, !requestURLString.isEmpty { exportVal["requestURLString"] = requestURLString}
        if let requestTimeoutInterval = self.requestTimeoutInterval, !requestTimeoutInterval.isEmpty { exportVal["requestTimeoutInterval"] = requestTimeoutInterval}
        if let requestCachePolicy = self.requestCachePolicy, !requestCachePolicy.isEmpty { exportVal["requestCachePolicy"] = requestCachePolicy}
        if let requestHTTPMethod = self.requestHTTPMethod, !requestHTTPMethod.isEmpty { exportVal["requestHTTPMethod"] = requestHTTPMethod}
        if let requestAllHTTPHeaderFields = self.requestAllHTTPHeaderFields, !requestAllHTTPHeaderFields.isEmpty { exportVal["requestAllHTTPHeaderFields"] = requestAllHTTPHeaderFields}
        if let requestHTTPBody = self.requestHTTPBody, !requestHTTPBody.isEmpty { exportVal["requestHTTPBody"] = requestHTTPBody}
        
        if let responseMIMEType = self.responseMIMEType, !responseMIMEType.isEmpty { exportVal["responseMIMEType"] = responseMIMEType}
        exportVal["responseExpectedContentLength"] = responseExpectedContentLength
        if let responseTextEncodingName = self.responseTextEncodingName, !responseTextEncodingName.isEmpty { exportVal["responseTextEncodingName"] = responseTextEncodingName}
        if let responseSuggestedFilename = self.responseSuggestedFilename, !responseSuggestedFilename.isEmpty { exportVal["responseSuggestedFilename"] = responseSuggestedFilename}
        exportVal["responseStatusCode"] = responseStatusCode
        if let responseAllHeaderFields = self.responseAllHeaderFields, !responseAllHeaderFields.isEmpty { exportVal["responseAllHeaderFields"] = responseAllHeaderFields}
        /*if let receiveDataString = self.receiveDataString, !receiveDataString.isEmpty { exportVal["receiveDataString"] = receiveDataString}*/
        if let duration = self.duration { exportVal["duration"] = duration}
        if let responseExpectedLength = self.responseExpectedLength { exportVal["responseExpectedLength"] = responseExpectedLength}
        return exportVal
    }
    
    func initialize(request:URLRequest?) {
        self.type = .network
        self.requestURLString = request?.url?.absoluteString
        self.requestCachePolicy = request?.cachePolicy.stringName()
        self.requestTimeoutInterval = request != nil ? String(request!.timeoutInterval) : "nil"
        self.requestHTTPMethod = request?.httpMethod
        
        if let allHTTPHeaderFields = request?.allHTTPHeaderFields {
            allHTTPHeaderFields.forEach({ [unowned self](e:(key: String, value: String)) in
                if self.requestAllHTTPHeaderFields == nil {
                    self.requestAllHTTPHeaderFields = "\(e.key):\(e.value)\n"
                }else {
                    self.requestAllHTTPHeaderFields!.append("\(e.key):\(e.value)\n")
                }
            })
        }
        
        if let bodyData = request?.httpBody {
            self.requestHTTPBody = String(data: bodyData, encoding: String.Encoding.utf8)
        }
    }
    
    /// init the var of response
    ///
    /// - Parameters:
    ///   - response: instance of HTTPURLResponse
    ///   - data: response data
    func initialize(response: HTTPURLResponse?, data:Data?) {
        self.responseMIMEType = response?.mimeType
        self.responseExpectedContentLength = response?.expectedContentLength ?? 0
        self.responseTextEncodingName = response?.textEncodingName
        self.responseSuggestedFilename = response?.suggestedFilename
        
        self.responseStatusCode = response?.statusCode ?? 200
        
        response?.allHeaderFields.forEach { [unowned self] (e:(key: AnyHashable, value: Any)) in
            if self.responseAllHeaderFields == nil {
                self.responseAllHeaderFields = "\(e.key) : \(e.value)\n"
            }else {
                self.responseAllHeaderFields!.append("\(e.key) : \(e.value)\n")
            }
        }
        self.receiveData = data
        guard let data = data else {
            return
        }
        
        if self.responseMIMEType == "application/json" {
            self.receiveDataString = self.json(from: data)
        }else if self.responseMIMEType == "text/javascript" {
            let plistText = String(data: data, encoding: String.Encoding.utf8)
            self.receiveDataString = plistText
            
        }else if self.responseMIMEType == "application/xml" ||
            self.responseMIMEType == "text/xml" ||
            self.responseMIMEType == "text/plain" {
            let xmlString = String(data: data, encoding: String.Encoding.utf8)
            self.receiveDataString = xmlString
        }else if let mimeType = self.responseMIMEType{
            self.receiveDataString = "Untreated MimeType:\(mimeType)"
        }
        
        if let responseExpectedLength = response?.expectedContentLength {
            self.responseExpectedLength = Float(responseExpectedLength) / 1000000.0
        }
    }
    
    private func json(from data:Data?) -> String? {
        
        guard let data = data else {
            return nil
        }
        
        do {
            let returnValue = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            guard JSONSerialization.isValidJSONObject(returnValue) else {
                return nil;
            }
            let data = try JSONSerialization.data(withJSONObject: returnValue)
            return String(data: data, encoding: .utf8)
        } catch  {
            return nil
        }
    }
    
    override func tdd()->[String]{
        var tddSet = [String]()
        var data = [String:Any]()
        data["url"] = self.requestURLString
        data["statusCode"] = self.responseStatusCode
        data["method"] = self.requestHTTPMethod
        if let d = self.receiveData {
            data["data"] = d.base64EncodedString()
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions(rawValue: 0))
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                tddSet.append(jsonString)
            }
        }catch{
            
        }
        return tddSet
    }
}
