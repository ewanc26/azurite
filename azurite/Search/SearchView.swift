//
//  SearchView.swift
//  azurite
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
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.vertical, 10)

                if !vm.query.isEmpty {
                    Picker("Results", selection: $vm.tab) {
                        ForEach(SearchViewModel.Tab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }

                Divider()

                resultsArea
            }
            .navigationTitle("Search")
            .appNavigationDestinations(atProto: atProto)
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search Bluesky", text: $vm.query)
                .textFieldStyle(.plain)
                .onChange(of: vm.query) { vm.queryChanged() }
            if !vm.query.isEmpty {
                Button { vm.query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
    }

    // MARK: - Results area

    @ViewBuilder
    private var resultsArea: some View {
        if vm.query.trimmingCharacters(in: .whitespaces).isEmpty {
            ContentUnavailableView(
                "Search Bluesky",
                systemImage: "magnifyingglass",
                description: Text("Find posts and people.")
            )
        } else if vm.isSearching && vm.posts.isEmpty && vm.people.isEmpty {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch vm.tab {
            case .posts:
                if vm.posts.isEmpty {
                    ContentUnavailableView.search(text: vm.query)
                } else {
                    postsList
                }
            case .people:
                if vm.people.isEmpty {
                    ContentUnavailableView.search(text: vm.query)
                } else {
                    peopleList
                }
            }
        }
    }

    // MARK: - Posts list

    private var postsList: some View {
        List {
            ForEach(vm.posts, id: \.uri) { post in
                PostRowView(post: post, atProto: atProto)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .task {
                        if post.uri == vm.posts.last?.uri {
                            await vm.loadMorePosts()
                        }
                    }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - People list

    private var peopleList: some View {
        List {
            ForEach(vm.people, id: \.actorDID) { person in
                PersonRowView(person: person, atProto: atProto)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .task {
                        if person.actorDID == vm.people.last?.actorDID {
                            await vm.loadMorePeople()
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
}
