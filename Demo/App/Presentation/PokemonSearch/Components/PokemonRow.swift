//
//  PokemonRow.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import SwiftUI

struct PokemonRow: View {
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

#Preview {
    PokemonRow(
        pokemon: PokemonSearchPreviewData.pikachu,
        colorName: PokemonSearchPreviewData.pikachuSpecies.colorName
    )
    .padding()
    .background(PokemonColorMapper.backgroundColor(for: PokemonSearchPreviewData.pikachuSpecies.colorName))
}
