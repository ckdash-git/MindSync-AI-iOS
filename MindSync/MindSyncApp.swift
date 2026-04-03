//
//  MindSyncApp.swift
//  MindSync
//
//  Created by CHANDAN on 03/04/26.
//

import SwiftUI

@main
struct MindSyncApp: App {

    private let container = DependencyContainer.shared

    var body: some Scene {
        WindowGroup {
            ChatView(viewModel: container.makeChatViewModel())
        }
    }
}
