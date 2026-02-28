//
//  SearchPostRowView.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

/// A post row that takes a bare `PostViewDefinition` (e.g. from search results),
/// as distinct from `PostRowView` which takes the full `FeedViewPostDefinition`.
struct SearchPostRowView: View {

    let post: AppBskyLexicon.Feed.PostViewDefinition

    private var author: AppBskyLexicon.Actor.ProfileViewBasicDefinition { post.author }

    private var postText: String? {
        post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(url: author.avatarImageURL)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(author.displayName ?? author.actorHandle)
                        .fontWeight(.semibold)
                    Text("@\(author.actorHandle)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(post.indexedAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .font(.subheadline)

                if let text = postText, !text.isEmpty {
                    Text(text)
                        .font(.body)
                        .lineLimit(6)
                }

                HStack(spacing: 20) {
                    engagementLabel(icon: "bubble.left",        count: post.replyCount)
                    engagementLabel(icon: "arrow.2.squarepath", count: post.repostCount)
                    engagementLabel(icon: "heart",              count: post.likeCount)
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func engagementLabel(icon: String, count: Int?) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            if let count, count > 0 {
                Text(count.formatted(.number.notation(.compactName)))
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
