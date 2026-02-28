//
//  azuriteApp.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI

@main
struct azuriteApp: App {

    @State private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 900, height: 650)
    }
}
