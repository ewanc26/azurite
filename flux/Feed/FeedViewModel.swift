//
//  FeedViewModel.swift
//  flux
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

@Observable
final class FeedViewModel {

    // MARK: - State

    enum LoadState {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var posts: [AppBskyLexicon.Feed.FeedViewPostDefinition] = []
    private(set) var loadState: LoadState = .idle

    var isLoading: Bool {
        if case .loading = loadState { return true }
        return false
    }

    var errorMessage: String? {
        if case .failed(let msg) = loadState { return msg }
        return nil
    }

    // MARK: - Pagination

    private var cursor: String?
    private(set) var hasMore: Bool = true

    // MARK: - Dependencies

    private let atProto: ATProtoKit

    init(atProto: ATProtoKit) {
        self.atProto = atProto
    }

    // MARK: - Loading

    /// Fetches the first page, replacing any existing posts.
    func refresh() async {
        cursor = nil
        hasMore = true
        posts = []
        await loadNextPage()
    }

    /// Appends the next page of posts.
    func loadNextPage() async {
        guard !isLoading, hasMore else { return }
        loadState = .loading

        do {
            let output = try await atProto.getTimeline(limit: 50, cursor: cursor)
            let newPosts = output.feed

            if newPosts.isEmpty {
                hasMore = false
            } else {
                posts.append(contentsOf: newPosts)
                cursor = output.cursor
                hasMore = output.cursor != nil
            }

            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}
