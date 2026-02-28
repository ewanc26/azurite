//
//  FeedView.swift
//  flux
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

struct FeedView: View {

    @State private var viewModel: FeedViewModel
    @Environment(AuthViewModel.self) private var auth

    init(atProto: ATProtoKit) {
        _viewModel = State(initialValue: FeedViewModel(atProto: atProto))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.posts.isEmpty && viewModel.isLoading {
                    loadingView
                } else if viewModel.posts.isEmpty, case .failed(let msg) = viewModel.loadState {
                    errorView(message: msg)
                } else if viewModel.posts.isEmpty {
                    emptyView
                } else {
                    feedList
                }
            }
            .navigationTitle("Following")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Sign Out", role: .destructive) {
                        auth.logout()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            await viewModel.refresh()
        }
    }

    // MARK: - Subviews

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.posts.indices, id: \.self) { index in
                    let item = viewModel.posts[index]
                    PostRowView(item: item)
                        .task {
                            // Trigger pagination when approaching the end
                            if index == viewModel.posts.count - 10 {
                                await viewModel.loadNextPage()
                            }
                        }
                    Divider()
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }

                if !viewModel.hasMore {
                    Text("You're all caught up.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding()
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading feed…")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("Failed to load feed")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await viewModel.refresh() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No posts yet")
                .font(.headline)
            Text("Follow some accounts to see posts here.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
