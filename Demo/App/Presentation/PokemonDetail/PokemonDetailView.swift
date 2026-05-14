//
//  PokemonDetailView.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import SwiftUI

struct PokemonDetailView: View {
    let pokemon: Pokemon

    var body: some View {
        List {
            Section("Pokemon") {
                Text(PokemonNameFormatter.displayName(pokemon.name))
                    .font(.headline)
            }

            Section("Abilities") {
                if pokemon.abilities.isEmpty {
                    Text("No abilities found.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(pokemon.abilities, id: \.self) { ability in
                        Text(PokemonNameFormatter.displayName(ability))
                    }
                }
            }
        }
        .navigationTitle(PokemonNameFormatter.displayName(pokemon.name))
    }
}
