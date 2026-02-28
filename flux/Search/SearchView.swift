//
//  SearchView.swift
//  flux
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI

struct SearchView: View {
    var body: some View {
        ContentUnavailableView(
            "Search",
            systemImage: "magnifyingglass",
            description: Text("Coming soon.")
        )
        .navigationTitle("Search")
    }
}
