//
//  PokemonSearchView.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import SwiftUI

struct PokemonSearchView: View {
    @State private var viewModel = PokemonSearchViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchField(text: $viewModel.searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                
                switch viewModel.state {
                case .idle:
                    ContentUnavailableView(
                        "Search Pokemon",
                        systemImage: "magnifyingglass",
                        description: Text("Type a species name to search the PokeAPI.")
                    )
                case .loading:
                    LoadingView()
                case .loaded(let content):
                    if content.species.isEmpty {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "questionmark.circle",
                            description: Text("Try a different species name.")
                        )
                    } else {
                        PokemonSpeciesList(
                            content: content,
                            bottomState: .idle,
                            onSpeciesAppear: viewModel.loadNextPageIfNeeded(currentSpecies:)
                        )
                    }
                case .loadingNextPage(let content):
                    PokemonSpeciesList(
                        content: content,
                        bottomState: .loading,
                        onSpeciesAppear: viewModel.loadNextPageIfNeeded(currentSpecies:)
                    )
                case .failed(let message):
                    ErrorStateView(message: message) {
                        viewModel.retrySearch()
                    }
                }
            }
            .navigationTitle("Pokemon Search")
            .navigationDestination(for: Pokemon.self) { pokemon in
                PokemonDetailView(pokemon: pokemon)
            }
        }
    }
}

#Preview {
    PokemonSearchView()
}
