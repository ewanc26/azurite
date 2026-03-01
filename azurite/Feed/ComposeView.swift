//
//  ComposeView.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

struct ComposeView: View {

    let atProto: ATProtoKit
    /// If set, this compose sheet is a reply to the given post.
    var replyTo: AppBskyLexicon.Feed.PostViewDefinition? = nil
    var onPosted: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var isPosting = false
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    private let limit = 300

    private var remaining: Int { limit - text.count }
    private var canPost: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && remaining >= 0
        && !isPosting
    }

    private var replyAuthorName: String? {
        guard let post = replyTo else { return nil }
        return post.author.displayName ?? "@\(post.author.actorHandle)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar row
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                Spacer()

                // Character counter
                Text("\(remaining)")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(remaining < 0 ? .red : remaining < 30 ? .orange : .secondary)

                Button(action: post) {
                    if isPosting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(replyTo != nil ? "Reply" : "Post")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(!canPost)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Error banner
            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(3)
                    Spacer()
                    Button {
                        errorMessage = nil
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(.red.opacity(0.08))

                Divider()
            }

            // Reply-to context
            if let post = replyTo,
               let postText = post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.text,
               let name = replyAuthorName {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Replying to \(name)", systemImage: "arrow.turn.up.left")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(postText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.fill.secondary, in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider()
            }

            // Text editor
            TextEditor(text: $text)
                .focused($isFocused)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minHeight: 120)

            Spacer(minLength: 0)
        }
        .frame(minWidth: 440, minHeight: 240)
        .onAppear { isFocused = true }
    }

    private func post() {
        guard canPost else { return }
        isPosting = true
        errorMessage = nil

        Task {
            do {
                let bluesky = ATProtoBluesky(atProtoKitInstance: atProto)

                // Build reply reference if replying
                var replyReference: AppBskyLexicon.Feed.PostRecord.ReplyReference? = nil
                if let parentPost = replyTo {
                    if let session = try await atProto.getUserSession() {
                        let ref = ComAtprotoLexicon.Repository.StrongReference(
                            recordURI: parentPost.uri,
                            cidHash: parentPost.cid
                        )
                        replyReference = try await ATProtoTools().createReplyReference(
                            from: ref,
                            session: session
                        )
                    }
                }

                _ = try await bluesky.createPostRecord(text: text, replyTo: replyReference)

                await MainActor.run {
                    onPosted?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isPosting = false
                }
            }
        }
    }
}

#Preview {
    Text("ComposeView")
}
