//
//  ProfileViewModel.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import Foundation
import ATProtoKit

@Observable
final class ProfileViewModel {

    private(set) var profile: AppBskyLexicon.Actor.ProfileViewDetailedDefinition? = nil
    private(set) var feed: [AppBskyLexicon.Feed.FeedViewPostDefinition] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var error: String? = nil
    private var feedCursor: String? = nil
    private var hasMoreFeed = true

    private let atProto: ATProtoKit
    let actorDID: String

    init(atProto: ATProtoKit, actorDID: String) {
        self.atProto = atProto
        self.actorDID = actorDID
    }

    // MARK: - Public

    func load() async {
        isLoading = true
        feedCursor = nil
        hasMoreFeed = true
        error = nil

        async let profileTask = atProto.getProfile(for: actorDID)
        async let feedTask    = atProto.getAuthorFeed(
            by: actorDID,
            limit: 30,
            postFilter: .postsWithNoReplies,
            shouldIncludePins: true
        )

        do {
            profile = try await profileTask
        } catch {
            self.error = error.localizedDescription
        }

        if let output = try? await feedTask {
            feed = output.feed
            feedCursor = output.cursor
            hasMoreFeed = output.cursor != nil
        }

        isLoading = false
    }

    func loadMoreFeed() async {
        guard !isLoadingMore, hasMoreFeed, let cursor = feedCursor else { return }
        isLoadingMore = true

        if let output = try? await atProto.getAuthorFeed(
            by: actorDID,
            limit: 30,
            cursor: cursor,
            postFilter: .postsWithNoReplies
        ) {
            feed += output.feed
            feedCursor = output.cursor
            hasMoreFeed = output.cursor != nil
        }

        isLoadingMore = false
    }
}
