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
        if viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ContentUnavailableView(
                "Search Pokemon",
                systemImage: "magnifyingglass",
                description: Text("Type a species name to search the PokeAPI.")
            )
        } else if viewModel.isLoading {
            LoadingView()
        } else if let message = viewModel.errorMessage, viewModel.species.isEmpty {
            ErrorStateView(message: message) {
                viewModel.retrySearch()
            }
        } else if viewModel.species.isEmpty {
            ContentUnavailableView(
                "No Results",
                systemImage: "questionmark.circle",
                description: Text("Try a different species name.")
            )
        } else {
            PokemonSpeciesList(viewModel: viewModel)
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
    @Bindable var viewModel: PokemonSearchViewModel

    var body: some View {
        List {
            ForEach(viewModel.species) { species in
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
                    viewModel.loadNextPageIfNeeded(currentSpecies: species)
                }
            }

            if viewModel.isLoadingNextPage {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let message = viewModel.errorMessage {
                Button {
                    if let lastSpecies = viewModel.species.last {
                        viewModel.loadNextPageIfNeeded(currentSpecies: lastSpecies)
                    }
                } label: {
                    Label(message, systemImage: "arrow.clockwise")
                }
            }
        }
        .listStyle(.plain)
    }
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
