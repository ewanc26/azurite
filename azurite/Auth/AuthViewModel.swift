//
//  AuthViewModel.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

/// Manages authentication state for the app.
@Observable
final class AuthViewModel {

    // MARK: - State

    enum AuthState {
        case unauthenticated
        case resolvingPDS          // handle → DID → PDS endpoint
        case authenticating        // session negotiation with the PDS
        case authenticated(ATProtoKit)
        case failed(String)
    }

    var state: AuthState = .unauthenticated

    var isAuthenticated: Bool {
        if case .authenticated = state { return true }
        return false
    }

    var atProto: ATProtoKit? {
        if case .authenticated(let kit) = state { return kit }
        return nil
    }

    // MARK: - Login

    func login(handle: String, appPassword: String) async {
        // Step 1 — resolve the PDS for this handle
        state = .resolvingPDS

        let pdsURL: String
        do {
            pdsURL = try await PDSResolver.resolvePDS(for: handle)
        } catch {
            state = .failed(error.localizedDescription)
            return
        }

        // Step 2 — authenticate against the resolved PDS
        state = .authenticating

        let config = ATProtocolConfiguration(pdsURL: pdsURL)

        do {
            try await config.authenticate(with: handle, password: appPassword)
            let kit = await ATProtoKit(sessionConfiguration: config)
            state = .authenticated(kit)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Logout

    func logout() {
        state = .unauthenticated
    }
}
