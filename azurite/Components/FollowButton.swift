//
//  FollowButton.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

/// A self-contained follow/unfollow button.
/// Owns its own optimistic state; pass `followingURI` from the model for the initial value.
struct FollowButton: View {

    let actorDID: String
    let atProto: ATProtoKit

    @State private var followingURI: String?
    @State private var isInFlight = false

    init(actorDID: String, followingURI: String?, atProto: ATProtoKit) {
        self.actorDID = actorDID
        self.atProto = atProto
        _followingURI = State(initialValue: followingURI)
    }

    var body: some View {
        Group {
            if isInFlight {
                ProgressView().controlSize(.small)
            } else if followingURI != nil {
                Button { Task { await toggle() } } label: {
                    Text("Following").fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.green)
            } else {
                Button { Task { await toggle() } } label: {
                    Text("Follow").fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.green)
            }
        }
        .disabled(isInFlight)
    }

    private func toggle() async {
        guard !isInFlight else { return }
        isInFlight = true
        defer { isInFlight = false }

        let bluesky = ATProtoBluesky(atProtoKitInstance: atProto)

        if let uri = followingURI {
            followingURI = nil
            do {
                try await bluesky.deleteRecord(.recordURI(atURI: uri))
            } catch {
                followingURI = uri // revert
            }
        } else {
            do {
                let result = try await bluesky.createFollowRecord(actorDID: actorDID)
                followingURI = result.recordURI
            } catch {}
        }
    }
}
