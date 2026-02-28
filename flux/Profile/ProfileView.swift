//
//  ProfileView.swift
//  flux
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

struct ProfileView: View {

    let atProto: ATProtoKit
    let actorDID: String

    @State private var vm: ProfileViewModel

    init(atProto: ATProtoKit, actorDID: String) {
        self.atProto = atProto
        self.actorDID = actorDID
        _vm = State(wrappedValue: ProfileViewModel(atProto: atProto, actorDID: actorDID))
    }

    var body: some View {
        Group {
            if vm.isLoading && vm.profile == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.error, vm.profile == nil {
                ContentUnavailableView(
                    "Couldn't load profile",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text(error)
                )
                .toolbar {
                    ToolbarItem {
                        Button("Retry") { Task { await vm.load() } }
                    }
                }
            } else if let profile = vm.profile {
                profileBody(profile: profile)
            }
        }
        .navigationTitle("Profile")
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    // MARK: - Body

    private func profileBody(profile: AppBskyLexicon.Actor.ProfileViewDetailedDefinition) -> some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {

                ProfileHeaderView(profile: profile)

                Divider()

                if vm.feed.isEmpty && !vm.isLoading {
                    ContentUnavailableView(
                        "No posts yet",
                        systemImage: "tray"
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(Array(vm.feed.enumerated()), id: \.element.post.uri) { index, item in
                        PostRowView(item: item)

                        if index < vm.feed.count - 1 {
                            Divider().padding(.leading, 72)
                        }

                        // Load-more trigger 10 posts from end
                        if index == vm.feed.count - 10 {
                            Color.clear
                                .frame(height: 1)
                                .task { await vm.loadMoreFeed() }
                        }
                    }

                    if vm.isLoadingMore {
                        ProgressView().padding()
                    }
                }
            }
        }
    }
}
