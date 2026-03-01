//
//  ProfileView.swift
//  azurite
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
        NavigationStack {
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
                        ToolbarItem { Button("Retry") { Task { await vm.load() } } }
                    }
                } else if let profile = vm.profile {
                    profileList(profile: profile)
                }
            }
            .navigationTitle("Profile")
            .appNavigationDestinations(atProto: atProto)
            .task { await vm.load() }
        }
    }

    // MARK: - List body

    private func profileList(profile: AppBskyLexicon.Actor.ProfileViewDetailedDefinition) -> some View {
        List {
            ProfileHeaderView(profile: profile, atProto: atProto, isOwnProfile: vm.isOwnProfile)

            if vm.feed.isEmpty && !vm.isLoading {
                ContentUnavailableView("No posts yet", systemImage: "tray")
                    .listRowSeparator(.hidden)
            } else {
                ForEach(Array(vm.feed.enumerated()), id: \.element.post.uri) { index, item in
                    PostRowView(item: item, atProto: atProto)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .task {
                            if index == vm.feed.count - 10 {
                                await vm.loadMoreFeed()
                            }
                        }
                }

                if vm.isLoadingMore {
                    HStack { ProgressView() }
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        .padding()
                }
            }
        }
        .listStyle(.plain)
        .refreshable { await vm.load() }
    }
}
