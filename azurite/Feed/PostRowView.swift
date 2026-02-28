//
//  PostRowView.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

struct PostRowView: View {

    let item: AppBskyLexicon.Feed.FeedViewPostDefinition

    private var post: AppBskyLexicon.Feed.PostViewDefinition { item.post }
    private var author: AppBskyLexicon.Actor.ProfileViewBasicDefinition { post.author }

    private var postText: String? {
        post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.text
    }

    private var repostAuthor: String? {
        guard let reason = item.reason,
              case .reasonRepost(let repost) = reason else { return nil }
        return repost.by.displayName ?? "@\(repost.by.actorHandle)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Repost banner
            if let reposter = repostAuthor {
                Label(reposter + " reposted", systemImage: "arrow.2.squarepath")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
            }

            HStack(alignment: .top, spacing: 12) {
                // Avatar
                AvatarView(url: author.avatarImageURL)

                VStack(alignment: .leading, spacing: 4) {
                    // Author line
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

                    // Post text
                    if let text = postText, !text.isEmpty {
                        Text(text)
                            .font(.body)
                            .lineLimit(20)
                    }

                    // Engagement counts
                    HStack(spacing: 20) {
                        engagementButton(icon: "bubble.left",       count: post.replyCount)
                        engagementButton(icon: "arrow.2.squarepath", count: post.repostCount)
                        engagementButton(icon: "heart",              count: post.likeCount)
                    }
                    .padding(.top, 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .contentShape(Rectangle())
    }

    private func engagementButton(icon: String, count: Int?) -> some View {
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

// MARK: - Avatar

struct AvatarView: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholderCircle
                }
            } else {
                placeholderCircle
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }

    private var placeholderCircle: some View {
        Circle()
            .fill(.quaternary)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundStyle(.secondary)
            )
    }
}
