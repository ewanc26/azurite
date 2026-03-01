//
//  SidebarView.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

struct SidebarView: View {

    @Binding var selection: SidebarItem?
    let unreadCount: Int
    let currentUser: AppBskyLexicon.Actor.ProfileViewDetailedDefinition?

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(SidebarItem.allCases) { item in
                    Label {
                        Text(item.title)
                    } icon: {
                        let isSelected = selection == item
                        Image(systemName: isSelected ? item.selectedIcon : item.icon)
                            .foregroundStyle(isSelected ? Color.bskyBlue : Color.primary)
                    }
                    .badge(item == .notifications && unreadCount > 0 ? unreadCount : 0)
                    .tag(item)
                }
            }
        }
        .listStyle(.sidebar)
        .tint(Color.bskyBlue)
        .safeAreaInset(edge: .bottom) {
            if let user = currentUser {
                userFooter(user: user)
            }
        }
    }

    // MARK: - User footer

    private func userFooter(user: AppBskyLexicon.Actor.ProfileViewDetailedDefinition) -> some View {
        HStack(spacing: 10) {
            AvatarView(url: user.avatarImageURL, size: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text(user.displayName ?? user.actorHandle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text("@\(user.actorHandle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
