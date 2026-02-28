//
//  NotificationsViewModel.swift
//  flux
//
//  Created by Ewan Croft on 28/02/2026.
//

import Foundation
import ATProtoKit

@Observable
final class NotificationsViewModel {

    enum LoadState { case idle, loading, loaded, error(String) }

    private(set) var notifications: [AppBskyLexicon.Notification.Notification] = []
    private(set) var state: LoadState = .idle
    private(set) var isLoadingMore = false
    private var cursor: String? = nil
    private var hasMore = true

    private let atProto: ATProtoKit

    init(atProto: ATProtoKit) {
        self.atProto = atProto
    }

    func refresh() async {
        state = .loading
        cursor = nil
        hasMore = true
        notifications = []
        await fetchPage()
        try? await atProto.updateSeen()
    }

    func loadNextPage() async {
        guard !isLoadingMore, hasMore, cursor != nil else { return }
        isLoadingMore = true
        await fetchPage()
        isLoadingMore = false
    }

    private func fetchPage() async {
        do {
            let output = try await atProto.listNotifications(limit: 50, cursor: cursor)
            notifications += output.notifications
            cursor = output.cursor
            hasMore = output.cursor != nil
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
