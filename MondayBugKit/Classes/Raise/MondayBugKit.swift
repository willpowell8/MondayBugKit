//
//  MondayBugKit.swift
//  MondayBugKit
//
//  Created by Will Powell on 01/11/2020.
//

import Foundation
import MBProgressHUD

public class MondayBugKit {
    
    public static var defaultOptions = RaiseOptions(viewControllerTitle: "Bug")
    
    public static var context = MondayBugKit()
    static let ACCESS_TOKEN = "MONDAY_ACCESS"
    
    var boardId:Int?
    var isAdminToken = false
    var admin_access_token:String?
    var access_token:String? {
        get{
            if admin_access_token != nil {
                return admin_access_token
            }
            return UserDefaults.standard.string(forKey: MondayBugKit.ACCESS_TOKEN)
        }
        set{
            UserDefaults.standard.set(newValue, forKey: MondayBugKit.ACCESS_TOKEN)
            UserDefaults.standard.synchronize()
        }
    }
    
    public func setup(admin_access_token:String? = nil, boardId:Int? = nil){
        if let admin_access_token = admin_access_token {
            self.admin_access_token = admin_access_token
            isAdminToken = true
        }
        self.boardId = boardId
    }
    
    static let AUTH_URL = "https://auth.monday.com/oauth2/authorize?client_id=9e1aa7b65b8a8e015f1c72111ce825bf"
    
    public func raiseBug(_ viewController:UIViewController? = nil, options:RaiseOptions? = MondayBugKit.defaultOptions){
        RemoteLog.context.exportZip()
        guard let vc = viewController else {
            return
        }
        if(access_token != nil){
            print("TODO CHECK AUTH")
            let hud = MBProgressHUD.showAdded(to: vc.view, animated: true)
            MondayAPI.getMe { (error, data) in
                if error {
                    DispatchQueue.main.async {
                        hud.hide(animated: true)
                        self.oauthAuthenticate(vc)
                    }
                    return
                }
                DispatchQueue.main.async {
                    hud.hide(animated: true)
                    self.raiseWithAuth(vc)
                }
            }
        }else{
            oauthAuthenticate(vc)
        }
    }
    
    func oauthAuthenticate(_ viewController:UIViewController, options:RaiseOptions? = MondayBugKit.defaultOptions){
        let podBundle = Bundle.init(for: MondayBugKit.self)
        let bundleURL = podBundle.url(forResource: "MondayBugKit", withExtension: "bundle")
        let bundle = Bundle(url: bundleURL!)!
        let controller = OAuthLoginViewController(nibName: "OauthViewController", bundle: bundle)
        controller.options = options
        let navContoller = UINavigationController(rootViewController: controller)
        viewController.present(navContoller, animated: true, completion: nil)
    }
    
    func raiseWithAuth(_ viewController:UIViewController, options:RaiseOptions? = MondayBugKit.defaultOptions){
        guard let boardId = self.boardId else {
            return
        }
        let hud = MBProgressHUD.showAdded(to: viewController.view, animated: true)
        MondayAPI.getBoard(boardId: boardId) { (error, board) in
            guard !error else{
                DispatchQueue.main.async {
                    hud.hide(animated: true)
                }
                // todo add error
                print("ERROR OCCURRED")
                return
            }
            guard board != nil else{
                // todo add board error
                DispatchQueue.main.async {
                    hud.hide(animated: true)
                }
                print("BOARD NOT FOUND")
                return
            }
            DispatchQueue.main.async {
                hud.hide(animated: true)
                let bugViewController = MondayBugViewController()
                bugViewController.options = options
                bugViewController.mondayBoard = board
                let nav = UINavigationController(rootViewController: bugViewController)
                viewController.present(nav, animated: true, completion: nil)
            }
        }
    }
}
