//
//  ProfileView.swift
//  flux
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        ContentUnavailableView(
            "Profile",
            systemImage: "person.circle",
            description: Text("Coming soon.")
        )
        .navigationTitle("Profile")
    }
}
