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

    // MARK: - Init

    init() {
        // Attempt to restore a previous session from the Keychain on launch.
        Task {
            await restoreSessionIfPossible()
        }
    }

    // MARK: - Session restoration

    private func restoreSessionIfPossible() async {
        guard let credentials = KeychainService.loadCredentials() else { return }
        await login(handle: credentials.handle, appPassword: credentials.appPassword, saveToKeychain: false)
    }

    // MARK: - Login

    /// Signs in with the given handle and app password.
    /// - Parameters:
    ///   - handle: The user's AT Protocol handle (e.g. `alice.bsky.social`).
    ///   - appPassword: The app password generated on bsky.app.
    ///   - saveToKeychain: Whether to persist the credentials after a successful login. Defaults to `true`.
    func login(handle: String, appPassword: String, saveToKeychain: Bool = true) async {
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

            if saveToKeychain {
                KeychainService.saveCredentials(handle: handle, appPassword: appPassword)
            }
        } catch {
            state = .failed(error.localizedDescription)
            // If restoration failed, clear any stale credentials so the user
            // isn't stuck in a silent failure loop.
            if !saveToKeychain {
                KeychainService.deleteCredentials()
            }
        }
    }

    // MARK: - Logout

    func logout() {
        KeychainService.deleteCredentials()
        state = .unauthenticated
    }
}
