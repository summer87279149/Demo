//
//  PokemonSpeciesList.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import SwiftUI

struct PokemonSpeciesList: View {
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

#Preview("Loaded") {
    NavigationStack {
        PokemonSpeciesList(
            content: PokemonSearchPreviewData.content,
            bottomState: .idle,
            onSpeciesAppear: { _ in },
            onRetryNextPage: {}
        )
    }
}

#Preview("Loading Next Page") {
    NavigationStack {
        PokemonSpeciesList(
            content: PokemonSearchPreviewData.content,
            bottomState: .loading,
            onSpeciesAppear: { _ in },
            onRetryNextPage: {}
        )
    }
}

#Preview("Next Page Failed") {
    NavigationStack {
        PokemonSpeciesList(
            content: PokemonSearchPreviewData.content,
            bottomState: .failed("Try again"),
            onSpeciesAppear: { _ in },
            onRetryNextPage: {}
        )
    }
}
