//
//  NotificationRowView.swift
//  flux
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

struct NotificationRowView: View {

    let notification: AppBskyLexicon.Notification.Notification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            reasonBadge
                .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    AvatarView(url: notification.author.avatarImageURL)
                        .frame(width: 34, height: 34)
                    Spacer()
                    Text(notification.indexedAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Text(summaryText)
                    .font(.subheadline)

                if let excerpt = postExcerpt {
                    Text(excerpt)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(notification.isRead ? Color.clear : Color.accentColor.opacity(0.05))
    }

    // MARK: - Computed helpers

    private var authorName: String {
        notification.author.displayName ?? "@\(notification.author.actorHandle)"
    }

    private var summaryText: String {
        switch notification.reason {
        case .like:              return "\(authorName) liked your post"
        case .repost:            return "\(authorName) reposted your post"
        case .follow:            return "\(authorName) followed you"
        case .mention:           return "\(authorName) mentioned you"
        case .reply:             return "\(authorName) replied to your post"
        case .quote:             return "\(authorName) quoted your post"
        case .starterpackjoined: return "\(authorName) joined via your starter pack"
        case .verified:          return "\(authorName) verified your account"
        case .unverified:        return "\(authorName) removed your verification"
        case .likeViaRepost:     return "\(authorName) liked a repost of yours"
        case .repostViaRepost:   return "\(authorName) reposted via your repost"
        case .subscribedPost:    return "\(authorName) posted (subscribed)"
        case .unknown(let v):    return "\(authorName) · \(v)"
        }
    }

    /// Show the post text when the notification itself contains a post record (replies, mentions, quotes).
    private var postExcerpt: String? {
        switch notification.reason {
        case .reply, .mention, .quote:
            return notification.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.text
        default:
            return nil
        }
    }

    // MARK: - Reason badge

    private var reasonBadge: some View {
        let (icon, color) = reasonStyle
        return ZStack {
            Circle().fill(color.opacity(0.15))
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private var reasonStyle: (String, Color) {
        switch notification.reason {
        case .like:              return ("heart.fill",            .pink)
        case .likeViaRepost:     return ("heart.fill",            .pink)
        case .repost:            return ("arrow.2.squarepath",    .green)
        case .repostViaRepost:   return ("arrow.2.squarepath",    .green)
        case .follow:            return ("person.badge.plus",     .blue)
        case .mention:           return ("at",                    .purple)
        case .reply:             return ("bubble.left.fill",      .blue)
        case .quote:             return ("quote.bubble.fill",     .indigo)
        case .starterpackjoined: return ("person.2.fill",         .orange)
        case .verified:          return ("checkmark.seal.fill",   .teal)
        case .unverified:        return ("xmark.seal.fill",       .gray)
        case .subscribedPost:    return ("bell.fill",             .yellow)
        case .unknown:           return ("questionmark.circle",   .gray)
        }
    }
}
