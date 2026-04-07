//
//  MindSyncApp.swift
//  MindSync
//
//  Created by CHANDAN on 03/04/26.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

// Firebase App Delegate for initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }

    // Handle Google Sign-In redirect URL
    func application(
        _: UIApplication,
        open url: URL,
        options _: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
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
                    AuthView(viewModel: authViewModel)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
            .task {
                await authViewModel.listenToAuthState()
            }
        }
    }
}
