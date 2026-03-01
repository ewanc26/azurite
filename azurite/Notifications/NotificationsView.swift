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
        NavigationStack {
            Group {
                switch vm.state {
                case .idle:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loading where vm.notifications.isEmpty:
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
            .appNavigationDestinations(atProto: atProto)
            .task { await vm.refresh() }
            .refreshable { await vm.refresh() }
        }
    }

    // MARK: - List

    private var notificationList: some View {
        List {
            ForEach(vm.notifications, id: \.uri) { notification in
                NotificationRowView(notification: notification, atProto: atProto)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .task {
                        if notification.uri == vm.notifications.last?.uri {
                            await vm.loadNextPage()
                        }
                    }
            }

            if vm.isLoadingMore {
                HStack { ProgressView() }
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .padding()
            }
        }
        .listStyle(.plain)
    }
}
