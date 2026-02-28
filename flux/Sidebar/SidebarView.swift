//
//  SidebarView.swift
//  flux
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
                        Image(systemName: selection == item ? item.selectedIcon : item.icon)
                    }
                    .badge(item == .notifications && unreadCount > 0 ? unreadCount : 0)
                    .tag(item)
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            if let user = currentUser {
                userFooter(user: user)
            }
        }
    }

    // MARK: - User footer

    private func userFooter(user: AppBskyLexicon.Actor.ProfileViewDetailedDefinition) -> some View {
        HStack(spacing: 10) {
            AvatarView(url: user.avatarImageURL)
                .frame(width: 32, height: 32)

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
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
