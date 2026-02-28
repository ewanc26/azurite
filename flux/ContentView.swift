//
//  ContentView.swift
//  flux
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI

struct ContentView: View {

    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        Group {
            switch auth.state {
            case .unauthenticated, .failed:
                LoginView(auth: auth)

            case .resolvingPDS, .authenticating:
                // Should be handled within LoginView, but guard against it here.
                ProgressView("Signing in…")
                    .frame(minWidth: 420, minHeight: 500)

            case .authenticated:
                // Placeholder — replace with your main feed view next.
                MainPlaceholderView()
            }
        }
    }
}

/// Temporary landing view shown after a successful login.
/// Replace this with your real feed/timeline view.
private struct MainPlaceholderView: View {

    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("You're in!")
                .font(.title.bold())
            Text("Feed coming soon.")
                .foregroundStyle(.secondary)
            Button("Sign out", role: .destructive) {
                auth.logout()
            }
            .buttonStyle(.bordered)
        }
        .frame(minWidth: 420, minHeight: 500)
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
}
