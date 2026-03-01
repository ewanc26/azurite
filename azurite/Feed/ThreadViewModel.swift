//
//  ThreadViewModel.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import Foundation
import ATProtoKit

@Observable
final class ThreadViewModel {

    enum State {
        case loading
        case loaded(AppBskyLexicon.Feed.ThreadViewPostDefinition)
        case error(String)
    }

    private(set) var state: State = .loading

    private let atProto: ATProtoKit
    let postURI: String

    init(atProto: ATProtoKit, postURI: String) {
        self.atProto = atProto
        self.postURI = postURI
    }

    func load() async {
        state = .loading
        do {
            let output = try await atProto.getPostThread(from: postURI, depth: 10, parentHeight: 20)
            if case .threadViewPost(let thread) = output.thread {
                state = .loaded(thread)
            } else if case .notFoundPost = output.thread {
                state = .error("Post not found.")
            } else if case .blockedPost = output.thread {
                state = .error("This post is blocked.")
            } else {
                state = .error("Couldn't load thread.")
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
