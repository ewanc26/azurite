//
//  ProfileHeaderView.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

struct ProfileHeaderView: View {

    let profile: AppBskyLexicon.Actor.ProfileViewDetailedDefinition
    let atProto: ATProtoKit
    let isOwnProfile: Bool

    init(
        profile: AppBskyLexicon.Actor.ProfileViewDetailedDefinition,
        atProto: ATProtoKit,
        isOwnProfile: Bool = false
    ) {
        self.profile = profile
        self.atProto = atProto
        self.isOwnProfile = isOwnProfile
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            bannerView
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .clipped()
                .listRowInsets(EdgeInsets())

            // Avatar row
            HStack(alignment: .center, spacing: 14) {
                AvatarView(url: profile.avatarImageURL, size: 64)

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.displayName ?? profile.actorHandle)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(1)

                    Text("@\(profile.actorHandle)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if !isOwnProfile {
                    followButton
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Bio
            if let bio = profile.description, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .lineLimit(6)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }

            // Stats
            HStack(spacing: 24) {
                statView(count: profile.followCount ?? 0, label: "Following")
                statView(count: profile.followerCount ?? 0, label: "Followers")
                statView(count: profile.postCount ?? 0, label: "Posts")
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }

    private var followButton: some View {
        FollowButton(
            actorDID: profile.actorDID,
            followingURI: profile.viewer?.followingURI,
            atProto: atProto
        )
    }

    // MARK: - Subviews

    private var bannerView: some View {
        Group {
            if let url = profile.bannerImageURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    LinearGradient.bannerPlaceholder
                }
            } else {
                LinearGradient.bannerPlaceholder
            }
        }
    }

    private func statView(count: Int, label: String) -> some View {
        HStack(spacing: 3) {
            Text(count.formatted(.number.notation(.compactName)))
                .fontWeight(.semibold)
            Text(label)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}
