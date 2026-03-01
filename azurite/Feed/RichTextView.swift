//
//  RichTextView.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

/// Renders Bluesky rich text with clickable mentions, hashtags, and URLs.
///
/// Facet byte offsets are UTF-8 based; this view handles the conversion correctly.
/// Mentions navigate to profiles, links open in the system browser, hashtags trigger a search.
struct RichTextView: View {

    let text: String
    let facets: [AppBskyLexicon.RichText.Facet]?

    /// Called when user taps a mention facet (passes the actor DID).
    var onMentionTapped: ((String) -> Void)? = nil

    /// Called when user taps a hashtag facet (passes the tag text, no # prefix).
    var onTagTapped: ((String) -> Void)? = nil

    var font: Font = .body
    var lineLimit: Int? = nil

    var body: some View {
        Text(attributedString)
            .font(font)
            .lineLimit(lineLimit)
            .environment(\.openURL, OpenURLAction { url in
                guard let scheme = url.scheme else { return .systemAction }

                if scheme == "azurite-profile",
                   let did = url.host {
                    onMentionTapped?(did)
                    return .handled
                }

                if scheme == "azurite-tag",
                   let tag = url.host {
                    onTagTapped?(tag)
                    return .handled
                }

                return .systemAction
            })
    }

    // MARK: - AttributedString builder

    private var attributedString: AttributedString {
        guard let facets, !facets.isEmpty else {
            return AttributedString(text)
        }

        // Work in UTF-8 bytes to match AT Proto byte offsets
        let utf8 = Array(text.utf8)
        var result = AttributedString()

        var cursor = 0 // current position in utf8 byte array

        // Sort facets by start byte so we can process left-to-right
        let sorted = facets
            .filter { $0.index.byteStart < $0.index.byteEnd && $0.index.byteEnd <= utf8.count }
            .sorted { $0.index.byteStart < $1.index.byteStart }

        for facet in sorted {
            let start = facet.index.byteStart
            let end = facet.index.byteEnd

            // Append plain text before this facet
            if cursor < start {
                let plain = String(bytes: utf8[cursor..<start], encoding: .utf8) ?? ""
                result += AttributedString(plain)
            }

            // Convert facet bytes to a String
            let facetText = String(bytes: utf8[start..<end], encoding: .utf8) ?? ""

            // Determine the first recognised feature
            let feature = facet.features.first

            var segment = AttributedString(facetText)

            switch feature {
            case .link(let link):
                if let url = URL(string: link.uri) {
                    segment.link = url
                    segment.foregroundColor = .accentColor
                }

            case .mention(let mention):
                // Use custom scheme so we can intercept and navigate internally
                let encoded = mention.did.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? mention.did
                if let url = URL(string: "azurite-profile://\(encoded)") {
                    segment.link = url
                    segment.foregroundColor = .accentColor
                }

            case .tag(let tag):
                let encoded = tag.tag.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? tag.tag
                if let url = URL(string: "azurite-tag://\(encoded)") {
                    segment.link = url
                    segment.foregroundColor = .accentColor
                }

            default:
                break
            }

            result += segment
            cursor = end
        }

        // Append any remaining plain text after the last facet
        if cursor < utf8.count {
            let tail = String(bytes: Array(utf8[cursor...]), encoding: .utf8) ?? ""
            result += AttributedString(tail)
        }

        return result
    }
}
