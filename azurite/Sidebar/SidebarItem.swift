//
//  SidebarItem.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI

/// The top-level destinations shown in the sidebar.
enum SidebarItem: String, CaseIterable, Identifiable {
    case following
    case notifications
    case search
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .following:     return "Following"
        case .notifications: return "Notifications"
        case .search:        return "Search"
        case .profile:       return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .following:     return "house"
        case .notifications: return "bell"
        case .search:        return "magnifyingglass"
        case .profile:       return "person.circle"
        }
    }

    var selectedIcon: String {
        switch self {
        case .following:     return "house.fill"
        case .notifications: return "bell.fill"
        case .search:        return "magnifyingglass"
        case .profile:       return "person.circle.fill"
        }
    }
}
