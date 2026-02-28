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
                ProgressView("Signing in…")
                    .frame(minWidth: 420, minHeight: 500)

            case .authenticated(let atProto):
                AppView(atProto: atProto)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
}
