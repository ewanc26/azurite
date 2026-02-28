//
//  PersonRowView.swift
//  flux
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

struct PersonRowView: View {

    let person: AppBskyLexicon.Actor.ProfileViewDefinition

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: person.avatarImageURL)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(person.displayName ?? person.actorHandle)
                        .fontWeight(.semibold)
                    Text("@\(person.actorHandle)")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .lineLimit(1)

                if let bio = person.description, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
