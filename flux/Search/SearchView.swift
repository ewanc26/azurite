//
//  SearchView.swift
//  flux
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI
import ATProtoKit

struct SearchView: View {

    let atProto: ATProtoKit
    @State private var vm: SearchViewModel

    init(atProto: ATProtoKit) {
        self.atProto = atProto
        _vm = State(wrappedValue: SearchViewModel(atProto: atProto))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar + tab picker
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search Bluesky", text: $vm.query)
                        .textFieldStyle(.plain)
                        .onChange(of: vm.query) { vm.queryChanged() }
                    if !vm.query.isEmpty {
                        Button {
                            vm.query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 16)

                if !vm.query.isEmpty {
                    Picker("Results", selection: $vm.tab) {
                        ForEach(SearchViewModel.Tab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 10)

            Divider()

            // Results
            Group {
                if vm.query.trimmingCharacters(in: .whitespaces).isEmpty {
                    emptyPrompt
                } else if vm.isSearching && vm.posts.isEmpty && vm.people.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    resultsView
                }
            }
        }
        .navigationTitle("Search")
    }

    // MARK: - States

    private var emptyPrompt: some View {
        ContentUnavailableView(
            "Search Bluesky",
            systemImage: "magnifyingglass",
            description: Text("Find posts and people.")
        )
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsView: some View {
        switch vm.tab {
        case .posts:
            if vm.posts.isEmpty && !vm.isSearching {
                noResults(for: "posts")
            } else {
                postsResults
            }
        case .people:
            if vm.people.isEmpty && !vm.isSearching {
                noResults(for: "people")
            } else {
                peopleResults
            }
        }
    }

    private var postsResults: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(vm.posts, id: \.uri) { post in
                    SearchPostRowView(post: post)
                    Divider().padding(.leading, 72)
                }

                // Load-more trigger
                if let last = vm.posts.last {
                    Color.clear
                        .frame(height: 1)
                        .id("posts-bottom-\(last.uri)")
                        .task { await vm.loadMorePosts() }
                }
            }
        }
    }

    private var peopleResults: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(vm.people, id: \.actorDID) { person in
                    PersonRowView(person: person)
                    Divider().padding(.leading, 72)
                }

                if let last = vm.people.last {
                    Color.clear
                        .frame(height: 1)
                        .id("people-bottom-\(last.actorDID)")
                        .task { await vm.loadMorePeople() }
                }
            }
        }
    }

    private func noResults(for kind: String) -> some View {
        ContentUnavailableView.search(text: vm.query)
    }
}
