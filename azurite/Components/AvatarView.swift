//
//  AvatarView.swift
//  azurite

import SwiftUI

struct AvatarView: View {
    let url: URL?
    var size: CGFloat = 42      // Bluesky standard avatar size
    var hasReply: Bool = false  // kept for API compat; drives thread-line, not the avatar itself

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholderCircle
                }
            } else {
                placeholderCircle
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        // Subtle inset border matching Bluesky's MediaInsetBorder
        .overlay {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        }
    }

    private var placeholderCircle: some View {
        Circle()
            .fill(Color.primary.opacity(0.08))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(Color.secondary)
            )
    }
}
