//
//  ProfileHeaderView.swift
//  flux
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

struct ProfileHeaderView: View {

    let profile: AppBskyLexicon.Actor.ProfileViewDetailedDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Banner
            bannerView
                .frame(maxWidth: .infinity)
                .frame(height: 130)
                .clipped()

            // Avatar overlapping the banner
            HStack(alignment: .bottom) {
                AvatarView(url: profile.avatarImageURL)
                    .frame(width: 76, height: 76)
                    .overlay(Circle().strokeBorder(Color(nsColor: .windowBackgroundColor), lineWidth: 4))
                    .offset(y: -22)
                    .padding(.leading, 16)

                Spacer()
            }
            .padding(.bottom, -22)

            // Name + handle + bio
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName ?? profile.actorHandle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(2)

                Text("@\(profile.actorHandle)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let bio = profile.description, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .padding(.top, 4)
                        .lineLimit(6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Stats
            HStack(spacing: 28) {
                statView(count: profile.followCount ?? 0, label: "Following")
                statView(count: profile.followerCount ?? 0, label: "Followers")
                statView(count: profile.postCount ?? 0, label: "Posts")
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Subviews

    private var bannerView: some View {
        Group {
            if let url = profile.bannerImageURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    bannerPlaceholder
                }
            } else {
                bannerPlaceholder
            }
        }
    }

    private var bannerPlaceholder: some View {
        LinearGradient(
            colors: [.blue.opacity(0.35), .purple.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
