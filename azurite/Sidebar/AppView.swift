//
//  AppView.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import Combine
import ATProtoKit

struct AppView: View {

    let atProto: ATProtoKit

    @Environment(AuthViewModel.self) private var auth
    @State private var selection: SidebarItem? = .following
    @State private var unreadCount: Int = 0
    @State private var currentUser: AppBskyLexicon.Actor.ProfileViewDetailedDefinition?
    @State private var sessionDID: String?

    private let notificationTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selection: $selection,
                unreadCount: unreadCount,
                currentUser: currentUser
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        auth.logout()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .help("Sign out")
                }
            }
        } detail: {
            detailView
        }
        .task { await loadInitialData() }
        .onReceive(notificationTimer) { _ in
            Task { await refreshUnreadCount() }
        }
    }

    // MARK: - Detail routing

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .following, .none:
            FeedView(atProto: atProto)

        case .notifications:
            NotificationsView(atProto: atProto)

        case .search:
            SearchView(atProto: atProto)

        case .profile:
            if let did = sessionDID {
                ProfileView(atProto: atProto, actorDID: did)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Data loading

    private func loadInitialData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadCurrentUser() }
            group.addTask { await refreshUnreadCount() }
        }
    }

    private func loadCurrentUser() async {
        guard let session = try? await atProto.getUserSession() else { return }
        sessionDID = session.sessionDID
        currentUser = try? await atProto.getProfile(for: session.sessionDID)
    }

    private func refreshUnreadCount() async {
        let output = try? await atProto.getUnreadCount(priority: nil)
        unreadCount = output?.count ?? 0
    }
}
