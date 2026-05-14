//
//  PokemonSearchView.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import SwiftUI

struct PokemonSearchView: View {
    @Bindable var viewModel: PokemonSearchViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchField(text: $viewModel.searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                content
            }
            .navigationTitle("Pokemon Search")
            .navigationDestination(for: Pokemon.self) { pokemon in
                PokemonDetailView(pokemon: pokemon)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
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
                    onSpeciesAppear: viewModel.loadNextPageIfNeeded(currentSpecies:),
                    onRetryNextPage: {}
                )
            }
        case .loadingNextPage(let content):
            PokemonSpeciesList(
                content: content,
                bottomState: .loading,
                onSpeciesAppear: viewModel.loadNextPageIfNeeded(currentSpecies:),
                onRetryNextPage: {}
            )
        case .failed(let message):
            ErrorStateView(message: message) {
                viewModel.retrySearch()
            }
        case .nextPageFailed(let content, let message):
            PokemonSpeciesList(
                content: content,
                bottomState: .failed(message),
                onSpeciesAppear: viewModel.loadNextPageIfNeeded(currentSpecies:),
                onRetryNextPage: viewModel.retryNextPage
            )
        }
    }
}

private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search species", text: $text)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hourglass.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.blue)
            ProgressView("Searching")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Search Failed", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct PokemonSpeciesList: View {
    let content: PokemonSearchContent
    let bottomState: PaginationBottomState
    let onSpeciesAppear: (PokemonSpecies) -> Void
    let onRetryNextPage: () -> Void

    var body: some View {
        List {
            ForEach(content.species) { species in
                Section {
                    ForEach(species.pokemons) { pokemon in
                        NavigationLink(value: pokemon) {
                            PokemonRow(pokemon: pokemon, colorName: species.colorName)
                        }
                        .listRowBackground(PokemonColorMapper.backgroundColor(for: species.colorName))
                    }
                } header: {
                    SpeciesHeaderView(species: species)
                }
                .onAppear {
                    onSpeciesAppear(species)
                }
            }

            switch bottomState {
            case .idle:
                EmptyView()
            case .loading:
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            case .failed(let message):
                Button {
                    onRetryNextPage()
                } label: {
                    Label(message, systemImage: "arrow.clockwise")
                }
            }
        }
        .listStyle(.plain)
    }
}

private enum PaginationBottomState {
    case idle
    case loading
    case failed(String)
}

private struct SpeciesHeaderView: View {
    let species: PokemonSpecies

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(PokemonNameFormatter.displayName(species.name))
                .font(.headline)
            Text("Capture rate: \(species.captureRate)")
                .font(.caption)
        }
        .textCase(nil)
    }
}

private struct PokemonRow: View {
    let pokemon: Pokemon
    let colorName: String

    var body: some View {
        Text(PokemonNameFormatter.displayName(pokemon.name))
            .font(.body.weight(.medium))
            .foregroundStyle(PokemonColorMapper.foregroundColor(for: colorName))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
    }
}
