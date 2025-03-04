//
//  AppDelegate.swift
//  QuickHealthKit
//
//  Created by galaxy on 2024/7/17.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        
        let vc = ViewController()
        window.rootViewController = vc
        
        return true
    }

}

