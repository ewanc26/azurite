//
//  AppTheme.swift
//  azurite
//
//  Central design tokens — Bluesky-faithful blue palette.

import SwiftUI

// MARK: - Brand colour

extension Color {
    /// Bluesky primary blue — used for links, active states, and accent chrome.
    static let bskyBlue = Color(red: 0.02, green: 0.44, blue: 1.0)   // #066CF7
    /// Active repost colour (green).
    static let bskyGreen = Color(red: 0.13, green: 0.77, blue: 0.37) // #22C55E
    /// Active like colour (red-pink).
    static let bskyRed = Color(red: 0.93, green: 0.18, blue: 0.31)   // #EC4451
}

// MARK: - Gradient palette (kept minimal — only used for banners etc.)

extension LinearGradient {
    /// Bluesky-style blue gradient (profile banners, splash screens).
    static let bskyPrimary = LinearGradient(
        colors: [Color(red: 0.02, green: 0.30, blue: 1.0),
                 Color(red: 0.35, green: 0.73, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle placeholder fill for profile banners.
    static let bannerPlaceholder = LinearGradient(
        colors: [Color.bskyBlue.opacity(0.35), Color.bskyBlue.opacity(0.20)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Card border modifier

/// Clips a view, adds a single-pixel border using the system separator colour, and a
/// very faint shadow — matching the style used for embedded cards in the Bluesky app.
struct BorderedCard: ViewModifier {
    var cornerRadius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 0.5)
            }
    }
}

extension View {
    func borderedCard(cornerRadius: CGFloat = 10) -> some View {
        modifier(BorderedCard(cornerRadius: cornerRadius))
    }

    /// Legacy alias kept so callers that still say `.glowingCard()` compile.
    func glowingCard(cornerRadius: CGFloat = 10) -> some View {
        borderedCard(cornerRadius: cornerRadius)
    }
}
