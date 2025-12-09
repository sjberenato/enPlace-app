//
//  EnPlaceApp.swift
//  EnPlace
//
//  Created by Sam Berenato on 12/1/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

// Firebase App Delegate for initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("✅ Firebase initialized successfully!")
        return true
    }
}

@main
struct EnPlaceApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
