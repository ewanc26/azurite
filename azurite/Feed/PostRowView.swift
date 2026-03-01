//
//  PostRowView.swift
//  azurite
//
//  Layout mirrors the Bluesky app (social-app):
//    outer   paddingLeft 10 / paddingRight 15
//    avi col paddingLeft 8  / width 42 / paddingRight 10   → content starts at x=70
//    reason  row sits above the main layout, icon+text indented to x=70
//    thread  2 pt solid separator colour, grows to fill avi column

import SwiftUI
import ATProtoKit

// MARK: - Bluesky avatar column geometry (matches social-app constants)
private let kAviColLeading:  CGFloat = 8
private let kAviSize:        CGFloat = 42
private let kAviColTrailing: CGFloat = 10
/// Total left indent for the text column (outer leading + avi col)
private let kContentLeading: CGFloat = 10 + kAviColLeading + kAviSize + kAviColTrailing  // 70

struct PostRowView: View {

    @Environment(\.isFocused) private var isFocused

    let post:   AppBskyLexicon.Feed.PostViewDefinition
    let reason: AppBskyLexicon.Feed.FeedViewPostDefinition.ReasonUnion?
    let atProto: ATProtoKit

    private var author: AppBskyLexicon.Actor.ProfileViewBasicDefinition { post.author }

    private var postRecord: AppBskyLexicon.Feed.PostRecord? {
        post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)
    }
    private var postText:   String?  { postRecord?.text }
    private var postFacets: [AppBskyLexicon.RichText.Facet]? { postRecord?.facets }

    private var repostAuthor: String? {
        guard let reason, case .reasonRepost(let r) = reason else { return nil }
        return r.by.displayName ?? "@\(r.by.actorHandle)"
    }

    private var hasReply: Bool { postRecord?.reply != nil }

    // MARK: Interaction state

    @State private var likeURI:     String?
    @State private var repostURI:   String?
    @State private var likeCount:   Int
    @State private var repostCount: Int
    @State private var isLiking    = false
    @State private var isReposting = false
    @State private var showingReply = false

    // MARK: Init

    init(item: AppBskyLexicon.Feed.FeedViewPostDefinition, atProto: ATProtoKit) {
        self.post    = item.post
        self.reason  = item.reason
        self.atProto = atProto
        _likeURI     = State(initialValue: item.post.viewer?.likeURI)
        _repostURI   = State(initialValue: item.post.viewer?.repostURI)
        _likeCount   = State(initialValue: item.post.likeCount ?? 0)
        _repostCount = State(initialValue: item.post.repostCount ?? 0)
    }

    init(post: AppBskyLexicon.Feed.PostViewDefinition, atProto: ATProtoKit) {
        self.post    = post
        self.reason  = nil
        self.atProto = atProto
        _likeURI     = State(initialValue: post.viewer?.likeURI)
        _repostURI   = State(initialValue: post.viewer?.repostURI)
        _likeCount   = State(initialValue: post.likeCount ?? 0)
        _repostCount = State(initialValue: post.repostCount ?? 0)
    }

    // MARK: Body

    var body: some View {
        // The entire row (minus action buttons) navigates to the thread.
        // Inner NavigationLinks on the avatar/author intercept those specific taps.
        NavigationLink(value: AppDestination.thread(postURI: post.uri)) {
            rowContent
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingReply) {
            ComposeView(atProto: atProto, replyTo: post)
        }
    }

    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Repost / pin reason banner ──────────────────────────────────
            if let reposter = repostAuthor {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.2.squarepath")
                    Text("\(reposter) reposted")
                }
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.leading, kContentLeading)
                .padding(.top, 6)
                .padding(.bottom, 2)
            }

            // ── Main row: avatar col + content ─────────────────────────────
            HStack(alignment: .top, spacing: 0) {

                // Avatar column — NavigationLink intercepts taps here → profile
                VStack(spacing: 0) {
                    NavigationLink(value: AppDestination.profile(actorDID: author.actorDID)) {
                        AvatarView(url: author.avatarImageURL, size: kAviSize, hasReply: hasReply)
                    }
                    .buttonStyle(.plain)

                    if hasReply {
                        Rectangle()
                            .fill(Color.primary.opacity(0.15))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                            .padding(.top, 4)
                            .padding(.bottom, -14)
                    }
                }
                .padding(.leading, kAviColLeading)
                .padding(.trailing, kAviColTrailing)

                // Text content column
                VStack(alignment: .leading, spacing: 3) {
                    postMetaRow
                    postBody
                    actionsRow
                }
                .padding(.bottom, 8)
            }
            .padding(.leading, 10)
            .padding(.trailing, 15)
            .padding(.top, repostAuthor == nil ? 10 : 6)

            Divider()
        }
        .background(isFocused ? Color.bskyBlue.opacity(0.04) : Color.clear)
    }

    // MARK: Post meta (author name · timestamp, handle)
    // NavigationLink intercepts taps on the name/handle → profile

    private var postMetaRow: some View {
        NavigationLink(value: AppDestination.profile(actorDID: author.actorDID)) {
            HStack(alignment: .center, spacing: 0) {
                // Display name — semibold
                Text(author.displayName ?? author.actorHandle)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .layoutPriority(1)

                // Handle — medium contrast, shrinks first
                Text("  @\(author.actorHandle)")
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
                    .layoutPriority(0)

                Spacer(minLength: 4)

                // Separator dot + relative timestamp
                Text("· \(Text(post.indexedAt, style: .relative))")
                    .foregroundStyle(Color.secondary)
            }
            .font(.subheadline)
        }
        .buttonStyle(.plain)
    }

    // MARK: Post body + embeds (plain — outer NavigationLink handles tap)

    private var postBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let text = postText, !text.isEmpty {
                RichTextView(
                    text: text,
                    facets: postFacets,
                    onMentionTapped: { _ in },
                    font: isFocused ? .title3 : .body,
                    lineLimit: isFocused ? nil : 20
                )
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.leading)
            }
            if let embed = post.embed {
                embedView(embed)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Embeds

    @ViewBuilder
    private func embedView(_ embed: AppBskyLexicon.Feed.PostViewDefinition.EmbedUnion) -> some View {
        switch embed {
        case .embedImagesView(let v):
            imagesView(v.images)
        case .embedExternalView(let v):
            externalLinkCard(v.external)
        case .embedRecordView(let v):
            if case .viewRecord(let r) = v.record { quotedPostCard(r) }
        case .embedRecordWithMediaView(let v):
            VStack(alignment: .leading, spacing: 6) {
                if case .embedImagesView(let imgs) = v.media { imagesView(imgs.images) }
                if case .viewRecord(let r) = v.record.record { quotedPostCard(r) }
            }
        default:
            EmptyView()
        }
    }

    private func imagesView(_ images: [AppBskyLexicon.Embed.ImagesDefinition.ViewImage]) -> some View {
        let cols = images.count == 1 ? 1 : 2
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: cols),
            spacing: 4
        ) {
            ForEach(images.indices, id: \.self) { i in
                AsyncImage(url: images[i].thumbnailImageURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Color.primary.opacity(0.06))
                }
                .frame(maxWidth: .infinity)
                .frame(height: images.count == 1 ? 200 : 120)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay { RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08), lineWidth: 0.5) }
            }
        }
    }

    private func externalLinkCard(
        _ external: AppBskyLexicon.Embed.ExternalDefinition.ViewExternal
    ) -> some View {
        HStack(spacing: 10) {
            if let thumbURL = external.thumbnailImageURL {
                AsyncImage(url: thumbURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Color.primary.opacity(0.06))
                }
                .frame(width: 56, height: 56)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(external.title)
                    .font(.subheadline).fontWeight(.medium)
                    .lineLimit(2).foregroundStyle(Color.primary)
                Text(URL(string: external.uri)?.host ?? external.uri)
                    .font(.caption).foregroundStyle(Color.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.primary.opacity(0.04))
        .borderedCard()
    }

    private func quotedPostCard(
        _ record: AppBskyLexicon.Embed.RecordDefinition.ViewRecord
    ) -> some View {
        let quotedText = record.value.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.text
        return NavigationLink(value: AppDestination.thread(postURI: record.uri)) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    // Small inline avatar
                    AvatarView(url: record.author.avatarImageURL, size: 18)
                    Text(record.author.displayName ?? record.author.actorHandle)
                        .font(.footnote).fontWeight(.semibold)
                        .foregroundStyle(Color.primary).lineLimit(1)
                    Text("@\(record.author.actorHandle)")
                        .font(.footnote).foregroundStyle(Color.secondary).lineLimit(1)
                }
                if let text = quotedText, !text.isEmpty {
                    Text(text).font(.subheadline).lineLimit(4).foregroundStyle(Color.primary)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.04))
            .borderedCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: Actions row
    // Layout mirrors PostControls in social-app:
    //   left  side: reply · repost · like   (equal flex slots, maxWidth 320)
    //   right side: bookmarks / share / menu  (gap-xs)

    private var actionsRow: some View {
        HStack(spacing: 0) {
            // ── Left group ────────────────────────────────────────────────
            HStack(spacing: 0) {
                // Reply
                actionButton(
                    icon: "bubble",
                    count: post.replyCount,
                    isActive: false,
                    activeColor: .bskyBlue
                ) { showingReply = true }

                // Repost
                actionButton(
                    icon: "arrow.2.squarepath",
                    count: repostCount,
                    isActive: repostURI != nil,
                    activeColor: .bskyGreen,
                    isDisabled: isReposting
                ) { Task { await toggleRepost() } }

                // Like
                actionButton(
                    icon: "heart",
                    count: likeCount,
                    isActive: likeURI != nil,
                    activeColor: .bskyRed,
                    isDisabled: isLiking
                ) { Task { await toggleLike() } }
            }
            .frame(maxWidth: 300, alignment: .leading)

            Spacer(minLength: 0)

            // ── Right group ───────────────────────────────────────────────
            HStack(spacing: 12) {
                Button { } label: {
                    Image(systemName: "square.and.arrow.up")
                        .imageScale(.small)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.secondary)

                Button { } label: {
                    Image(systemName: "ellipsis")
                        .imageScale(.small)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.secondary)
            }
        }
        .font(.callout)
        .monospacedDigit()
        .padding(.top, 4)
    }

    /// A single action button: icon (filled when active) + optional count.
    private func actionButton(
        icon: String,
        count: Int?,
        isActive: Bool,
        activeColor: Color,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isActive ? "\(icon).fill" : icon)
                    .imageScale(.medium)
                    .symbolEffect(.bounce, value: isActive)
                if let count, count > 0 {
                    Text(count.formatted(.number.notation(.compactName)))
                        .font(.footnote)
                        .contentTransition(.numericText(value: Double(count)))
                        .animation(.smooth, value: count)
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? activeColor : Color.secondary)
        .disabled(isDisabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .padding(.leading, -4)   // mirror social-app's negative marginLeft on first button
    }

    // MARK: Toggle actions

    private func toggleLike() async {
        guard !isLiking else { return }
        isLiking = true
        defer { isLiking = false }
        let bluesky = ATProtoBluesky(atProtoKitInstance: atProto)
        if let uri = likeURI {
            likeURI = nil; likeCount = max(0, likeCount - 1)
            do { try await bluesky.deleteRecord(.recordURI(atURI: uri)) }
            catch { likeURI = uri; likeCount += 1 }
        } else {
            likeCount += 1
            do {
                let ref = ComAtprotoLexicon.Repository.StrongReference(
                    recordURI: post.uri, cidHash: post.cid)
                likeURI = try await bluesky.createLikeRecord(ref).recordURI
            } catch { likeCount = max(0, likeCount - 1) }
        }
    }

    private func toggleRepost() async {
        guard !isReposting else { return }
        isReposting = true
        defer { isReposting = false }
        let bluesky = ATProtoBluesky(atProtoKitInstance: atProto)
        if let uri = repostURI {
            repostURI = nil; repostCount = max(0, repostCount - 1)
            do { try await bluesky.deleteRecord(.recordURI(atURI: uri)) }
            catch { repostURI = uri; repostCount += 1 }
        } else {
            repostCount += 1
            do {
                let ref = ComAtprotoLexicon.Repository.StrongReference(
                    recordURI: post.uri, cidHash: post.cid)
                repostURI = try await bluesky.createRepostRecord(ref).recordURI
            } catch { repostCount = max(0, repostCount - 1) }
        }
    }
}
