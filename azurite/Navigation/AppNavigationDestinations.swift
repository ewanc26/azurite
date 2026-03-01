//
//  AppNavigationDestinations.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

extension View {
    /// Registers navigation destinations for `AppDestination` on the enclosing NavigationStack.
    func appNavigationDestinations(atProto: ATProtoKit) -> some View {
        navigationDestination(for: AppDestination.self) { destination in
            switch destination {
            case .thread(let uri):
                ThreadView(atProto: atProto, postURI: uri)
            case .profile(let did):
                ProfileView(atProto: atProto, actorDID: did)
            }
        }
    }
}
