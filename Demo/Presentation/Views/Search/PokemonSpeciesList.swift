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
            onSpeciesAppear: { _ in }
        )
    }
}

#Preview("Loading Next Page") {
    NavigationStack {
        PokemonSpeciesList(
            content: PokemonSearchPreviewData.content,
            bottomState: .loading,
            onSpeciesAppear: { _ in }
        )
    }
}
