//
//  FeedView.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

struct FeedView: View {

    let atProto: ATProtoKit
    @State private var viewModel: FeedViewModel
    @State private var showingCompose = false

    init(atProto: ATProtoKit) {
        self.atProto = atProto
        _viewModel = State(initialValue: FeedViewModel(atProto: atProto))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.posts.isEmpty && viewModel.isLoading {
                    ProgressView("Loading feed…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.posts.isEmpty, case .failed(let msg) = viewModel.loadState {
                    ContentUnavailableView(
                        "Failed to load feed",
                        systemImage: "exclamationmark.triangle",
                        description: Text(msg)
                    )
                    .toolbar {
                        ToolbarItem { Button("Try Again") { Task { await viewModel.refresh() } } }
                    }
                } else if viewModel.posts.isEmpty {
                    ContentUnavailableView(
                        "No posts yet",
                        systemImage: "text.bubble",
                        description: Text("Follow some accounts to see posts here.")
                    )
                } else {
                    feedList
                }
            }
            .navigationTitle("Following")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingCompose = true } label: {
                        Label("New Post", systemImage: "square.and.pencil")
                    }
                    .help("Compose a post")
                }
            }
            .appNavigationDestinations(atProto: atProto)
            .sheet(isPresented: $showingCompose) {
                ComposeView(atProto: atProto) {
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        await viewModel.refresh()
                    }
                }
            }
        }
        .task { await viewModel.refresh() }
    }

    // MARK: - Feed list

    private var feedList: some View {
        List {
            ForEach(viewModel.posts.indices, id: \.self) { index in
                PostRowView(item: viewModel.posts[index], atProto: atProto)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .task {
                        if index == viewModel.posts.count - 10 {
                            await viewModel.loadNextPage()
                        }
                    }
            }

            if viewModel.isLoading {
                HStack { ProgressView() }
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .padding()
            }

            if !viewModel.hasMore {
                Text("You're all caught up.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .padding()
            }
        }
        .listStyle(.plain)
        .refreshable { await viewModel.refresh() }
    }
}
