//
//  PokemonTestFactory.swift
//  DemoTests
//
//  Created by xiatian on 5/14/26.
//

@testable import Demo

enum PokemonTestFactory {
    static func species(id: Int, name: String) -> PokemonSpecies {
        PokemonSpecies(
            id: id,
            name: name,
            captureRate: 45,
            colorName: "green",
            pokemons: [
                Pokemon(
                    id: id,
                    name: name,
                    abilities: ["overgrow"]
                )
            ]
        )
    }
}
