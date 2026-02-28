//
//  NotificationsView.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

struct NotificationsView: View {

    let atProto: ATProtoKit
    @State private var vm: NotificationsViewModel

    init(atProto: ATProtoKit) {
        self.atProto = atProto
        _vm = State(wrappedValue: NotificationsViewModel(atProto: atProto))
    }

    var body: some View {
        Group {
            switch vm.state {
            case .idle, 
                    .loading where vm.notifications.isEmpty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let message):
                ContentUnavailableView(
                    "Couldn't load notifications",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            default:
                notificationList
            }
        }
        .navigationTitle("Notifications")
        .task { await vm.refresh() }
        .refreshable { await vm.refresh() }
    }

    // MARK: - List

    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(vm.notifications, id: \.uri) { notification in
                    NotificationRowView(notification: notification)
                    Divider().padding(.leading, 66)
                }

                // Infinite scroll trigger
                if let last = vm.notifications.last {
                    Color.clear
                        .frame(height: 1)
                        .id("bottom-\(last.uri)")
                        .task { await vm.loadNextPage() }
                }

                if vm.isLoadingMore {
                    ProgressView().padding()
                }
            }
        }
    }
}
