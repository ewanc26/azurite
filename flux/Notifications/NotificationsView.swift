//
//  NotificationsView.swift
//  flux
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI

struct NotificationsView: View {
    var body: some View {
        ContentUnavailableView(
            "Notifications",
            systemImage: "bell",
            description: Text("Coming soon.")
        )
        .navigationTitle("Notifications")
    }
}
