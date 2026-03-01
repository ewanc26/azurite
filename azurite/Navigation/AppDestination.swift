//
//  AppDestination.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import Foundation

/// Navigation destinations shared across all NavigationStacks in the app.
enum AppDestination: Hashable {
    case thread(postURI: String)
    case profile(actorDID: String)
}
