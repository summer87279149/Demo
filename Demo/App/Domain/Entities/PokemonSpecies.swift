//
//  PokemonSpecies.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import Foundation

struct PokemonSpecies: Identifiable, Equatable {
    let id: Int
    let name: String
    let captureRate: Int
    let colorName: String
    let pokemons: [Pokemon]
}

struct PokemonSearchPage: Equatable {
    let items: [PokemonSpecies]
    let limit: Int
    let offset: Int

    var hasMorePages: Bool {
        items.count == limit
    }
}
