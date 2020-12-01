//
//  URLEmulator.swift
//


import Foundation

public class URLEmulation:NSObject {
    public var url:String?
    public var method:String? // post, get, delete etc
    public var mimeType:String?
    public var data:Data?
    public var duration:Double = 0
    public var textEncodingName:String?
    
    public convenience init(url:String?, method:String?, data:Data?,  mimeType:String? = nil, duration:Double = 0, textEncodingName:String? = nil){
        self.init()
        self.url = url
        self.method = method?.uppercased()
        self.mimeType = mimeType
        self.data = data
        self.duration = duration
        self.textEncodingName = textEncodingName
    }
    
    internal func getResponse(request:URLRequest)->URLResponse?{
        let contentLength = getData()?.count ?? 0
        return URLResponse(url: request.url!, mimeType: mimeType, expectedContentLength: contentLength, textEncodingName: textEncodingName)
    }
    
    internal func getData()->Data?{
        return self.data
    }
}

public class HTTPURLEmulation:URLEmulation {
    public var statusCode:Int = 200
    public var httpVersion:String?
    public var headerFields:[String:String]?
    
    override internal func getResponse(request: URLRequest) -> URLResponse? {
        return HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: httpVersion, headerFields: headerFields)
    }
    
    public convenience init(dictionary:[String:Any]){
        self.init()
        self.url = dictionary["url"] as? String
        self.method = dictionary["method"] as? String
        self.mimeType = dictionary["mimeType"] as? String
        self.duration = dictionary["duration"] as? Double ?? 0
        self.textEncodingName = dictionary["textEncodingName"] as? String
        if let dataBase64 = dictionary["data"] as? String {
            self.data = Data(base64Encoded: dataBase64)
        }
    }
    
    public convenience init(url:String?,method:String?, data:Data?,  statusCode:Int = 200, httpVersion:String? = nil, headerFields:[String:String]? = nil,  mimeType:String? = nil, duration:Double = 0, textEncodingName:String? = nil){
        self.init()
        self.url = url
        self.method = method?.uppercased()
        self.mimeType = mimeType
        self.data = data
        self.duration = duration
        self.textEncodingName = textEncodingName
    }
}

public enum URLEmulationMethod {
    case singleCalls // each call can only be made once
    case inOrder // each call must happen in order
    case byURL // url matches will return the data
}

public class URLEmulator {
    public var isEmulating = true // turn on and off the emulating
    public var bypassEmulationOnNoMatch = true // bypass emulation and make requests as normal if there is no match
    public var method:URLEmulationMethod = .byURL
    var emulations:[URLEmulation]? {
        didSet{
            var dictionary = [String:[URLEmulation]]()
            emulations?.forEach({ (emulation) in
                guard var url = emulation.url else {
                    return
                }
                if let method = emulation.method {
                    url = "\(method.uppercased())||\(url)"
                }
                if dictionary[url] == nil {
                    dictionary[url] = [emulation]
                }else{
                    dictionary[url]?.append(emulation)
                }
            })
            _emulationsByURL = dictionary
        }
    }
    var _emulationsByURL:[String:[URLEmulation]]?
    func shouldEmulate(request:URLRequest, completion: @escaping (_ data:Data?, _ urlResponse:URLResponse)->Void) -> Bool {
        guard let urlEmulation = findResponse(request: request), let response = urlEmulation.getResponse(request: request) else{
            return !bypassEmulationOnNoMatch
        }
        let data = urlEmulation.getData()
        completion(data, response)
        return true
    }
    
    func findResponse(request:URLRequest)->URLEmulation?{
        switch(method){
        case .byURL:
            guard var url = request.url?.absoluteString else {
                return nil
            }
            if let method = request.httpMethod {
                url = "\(method)||\(url)"
            }
            guard let set = _emulationsByURL?[url], set.count > 0 else {
                return nil
            }
            return set.first
        case .inOrder:
            print("TODO")
            return nil
        case .singleCalls:
            guard var url = request.url?.absoluteString else {
                return nil
            }
            if let method = request.httpMethod {
                url = "\(method)||\(url)"
            }
            guard var set = _emulationsByURL?[url], set.count > 0 else {
                return nil
            }
            // remove used service call
            set.remove(at: 0)
            _emulationsByURL?[url] = set
            return set.first
        }
    }
}
