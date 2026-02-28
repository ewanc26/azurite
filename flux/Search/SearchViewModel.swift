//
//  SearchViewModel.swift
//  flux
//
//  Created by Ewan Croft on 28/02/2026.
//

import Foundation
import ATProtoKit

@Observable
final class SearchViewModel {

    enum Tab: String, CaseIterable {
        case posts  = "Posts"
        case people = "People"
    }

    var query = ""
    var tab: Tab = .posts

    private(set) var posts:  [AppBskyLexicon.Feed.PostViewDefinition]   = []
    private(set) var people: [AppBskyLexicon.Actor.ProfileViewDefinition] = []
    private(set) var isSearching = false
    private(set) var error: String? = nil

    private var postCursor:   String? = nil
    private var peopleCursor: String? = nil
    private var debounceTask: Task<Void, Never>? = nil

    private let atProto: ATProtoKit

    init(atProto: ATProtoKit) {
        self.atProto = atProto
    }

    // MARK: - Public interface

    /// Call this from .onChange(of: query) — debounces automatically.
    func queryChanged() {
        debounceTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            posts = []
            people = []
            error = nil
            return
        }
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000) // 400 ms
            guard !Task.isCancelled else { return }
            await search(query: trimmed, reset: true)
        }
    }

    func loadMorePosts() async {
        guard let cursor = postCursor, !isSearching else { return }
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let output = try? await atProto.searchPosts(matching: trimmed, limit: 25, cursor: cursor) {
            posts += output.posts
            postCursor = output.cursor
        }
    }

    func loadMorePeople() async {
        guard let cursor = peopleCursor, !isSearching else { return }
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let output = try? await atProto.searchActors(matching: trimmed, cursor: cursor) {
            people += output.actors
            peopleCursor = output.cursor
        }
    }

    // MARK: - Private

    private func search(query: String, reset: Bool) async {
        if reset {
            postCursor = nil
            peopleCursor = nil
        }
        isSearching = true
        error = nil

        do {
            async let postsTask  = atProto.searchPosts(matching: query, limit: 25)
            async let peopleTask = atProto.searchActors(matching: query, limit: 25)
            let (postsOutput, peopleOutput) = try await (postsTask, peopleTask)

            if reset {
                posts  = postsOutput.posts
                people = peopleOutput.actors
            } else {
                posts  += postsOutput.posts
                people += peopleOutput.actors
            }
            postCursor   = postsOutput.cursor
            peopleCursor = peopleOutput.cursor
        } catch {
            self.error = error.localizedDescription
        }

        isSearching = false
    }
}
