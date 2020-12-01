//
//  AppDelegate.swift
//  MondayBugKit
//
//  Created by willpowell8 on 11/01/2020.
//  Copyright (c) 2020 willpowell8. All rights reserved.
//

import UIKit
import MondayBugKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        RemoteLog.context.setup()
        RemoteLog.context.profilingNetwork = true
        MondayBugKit.context.setup(admin_access_token:"eyJhbGciOiJIUzI1NiJ9.eyJ0aWQiOjg5NjYwNDgyLCJ1aWQiOjE2NjY1NzIxLCJpYWQiOiIyMDIwLTExLTAxVDEzOjQzOjAyLjAwMFoiLCJwZXIiOiJtZTp3cml0ZSJ9.rcVuQvJLETJcOCBW-oxSg1tsD0kY5-q6OkIAuBF2xVg", boardId:799667537)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

