//
//  OauthLogin.swift
//  MondayBugKit
//
//  Created by Will Powell on 01/11/2020.
//

import UIKit
import WebKit

class OAuthLoginViewController:UIViewController {
    
    @IBOutlet var webKitView:WKWebView?
    
    var options:RaiseOptions?
    
    override func viewDidLoad(){
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadWebKit()
    }
    
    func loadWebKit(){
        let request = URLRequest(url: URL(string:MondayBugKit.AUTH_URL)!)
        webKitView?.navigationDelegate = self
        webKitView?.load(request)
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
      guard let url = URLComponents(string: url) else { return nil }
      return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    func processCallBackURL(url:String){
        guard let code = getQueryStringParameter(url: url, param: "code") else{
            return
        }
        print("Got Code \(code)")
        requestToken(code: code)
    }
    
    func requestToken(code:String){
        let parameters = ["code": code, "client_id": "9e1aa7b65b8a8e015f1c72111ce825bf", "client_secret":"7312fcb76c26e89c2e614f853975d74b"]

        //create the url with URL
        let url = URL(string: "https://auth.monday.com/oauth2/token")! //change the url

        //create the session object
        let session = URLSession.shared

        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST

        do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
            } catch let error {
                print(error.localizedDescription)
            }

            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")

            //create dataTask using the session object to send data to the server
            let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

                guard error == nil else {
                    return
                }

                guard let data = data else {
                    return
                }

                do {
                    //create json object from data
                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        guard let access_token = json["access_token"] as? String else{
                            return
                        }
                        MondayBugKit.context.access_token = access_token
                        DispatchQueue.main.async {
                            self.completeToken()
                        }
                        
                        print(json)
                        // handle json...
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            })
            task.resume()
    }
    
    func completeToken(){
        guard let presentingViewController = self.presentingViewController else{
            return
        }
        dismiss(animated: true) {
            MondayBugKit.context.raiseWithAuth(presentingViewController, options: self.options)
        }
    }
    
}

extension OAuthLoginViewController : WKNavigationDelegate{
    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void){
        let status =  processUrl(url: navigationAction.request.url?.absoluteString)
        decisionHandler(status, preferences)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void){
        let status =  processUrl(url: navigationAction.request.url?.absoluteString)
        decisionHandler(status)
    }
    
    func processUrl(url:String?) ->WKNavigationActionPolicy{
        guard let url = url else{
            return .allow
        }
        if(url.contains("https://mobilelog.com/callback")){
            processCallBackURL(url: url)
            return .cancel
        }
        return .allow
    }
    
}

