//
//  SpeciesHeaderView.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import SwiftUI

struct SpeciesHeaderView: View {
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

#Preview {
    SpeciesHeaderView(species: PokemonSearchPreviewData.pikachuSpecies)
        .padding()
}
