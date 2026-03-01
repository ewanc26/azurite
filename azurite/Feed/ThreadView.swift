//
//  ThreadView.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

struct ThreadView: View {

    let atProto: ATProtoKit
    let postURI: String

    @State private var vm: ThreadViewModel
    @State private var showingReply = false
    @State private var focalPost: AppBskyLexicon.Feed.PostViewDefinition?
    @State private var parents: [AppBskyLexicon.Feed.PostViewDefinition] = []
    @State private var replies: [AppBskyLexicon.Feed.PostViewDefinition] = []

    init(atProto: ATProtoKit, postURI: String) {
        self.atProto = atProto
        self.postURI = postURI
        _vm = State(wrappedValue: ThreadViewModel(atProto: atProto, postURI: postURI))
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                switch vm.state {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)

                case .error(let msg):
                    ContentUnavailableView(
                        "Couldn't load thread",
                        systemImage: "bubble.left.and.exclamationmark.bubble.right",
                        description: Text(msg)
                    )
                    .listRowSeparator(.hidden)

                case .loaded:
                    ForEach(parents, id: \.uri) { post in
                        PostRowView(post: post, atProto: atProto)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                    }

                    if let post = focalPost {
                        PostRowView(post: post, atProto: atProto)
                            .environment(\.isFocused, true)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .id("focusedPost")
                    }

                    ForEach(replies, id: \.uri) { post in
                        PostRowView(post: post, atProto: atProto)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                    }

                    Color.clear.frame(height: 200).listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Post")
            .appNavigationDestinations(atProto: atProto)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingReply = true } label: {
                        Label("Reply", systemImage: "bubble.left")
                    }
                    .disabled(focalPost == nil)
                }
            }
            .task {
                await vm.load()
                if case .loaded(let thread) = vm.state {
                    processThread(thread)
                    if !parents.isEmpty {
                        proxy.scrollTo("focusedPost", anchor: .top)
                    }
                }
            }
            .refreshable {
                await vm.load()
                if case .loaded(let thread) = vm.state { processThread(thread) }
            }
            .sheet(isPresented: $showingReply) {
                if let post = focalPost {
                    ComposeView(atProto: atProto, replyTo: post) {
                        Task {
                            await vm.load()
                            if case .loaded(let thread) = vm.state { processThread(thread) }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Thread processing (mirrors IcySky's PostDetailView)

    private func processThread(_ thread: AppBskyLexicon.Feed.ThreadViewPostDefinition) {
        focalPost = thread.post
        parents = []
        replies = []
        collectParents(from: thread)
        collectReplies(from: thread)
    }

    private func collectParents(from thread: AppBskyLexicon.Feed.ThreadViewPostDefinition) {
        guard let parent = thread.parent,
              case .threadViewPost(let parentThread) = parent else { return }
        collectParents(from: parentThread)
        parents.append(parentThread.post)
    }

    private func collectReplies(from thread: AppBskyLexicon.Feed.ThreadViewPostDefinition) {
        guard let replyList = thread.replies else { return }
        for reply in replyList {
            guard case .threadViewPost(let replyThread) = reply else { continue }
            replies.append(replyThread.post)
            if !(replyThread.replies ?? []).isEmpty {
                collectReplies(from: replyThread)
            }
        }
    }
}
