//
//  MindSyncApp.swift
//  MindSync
//
//  Created by CHANDAN on 03/04/26.
//

import SwiftUI
import FirebaseCore

// Firebase App Delegate for initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct MindSyncApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = DependencyContainer.shared.makeAuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    ContentView()
                } else {
                    AuthView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
            .task {
                await authViewModel.listenToAuthState()
            }
        }
    }
}
