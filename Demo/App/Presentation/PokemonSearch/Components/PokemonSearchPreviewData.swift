//
//  PokemonSearchPreviewData.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

enum PokemonSearchPreviewData {
    static let pikachu = Pokemon(
        id: 25,
        name: "pikachu",
        abilities: ["static", "lightning-rod"]
    )

    static let pikachuLibre = Pokemon(
        id: 10084,
        name: "pikachu-libre",
        abilities: ["static", "lightning-rod"]
    )

    static let pikachuSpecies = PokemonSpecies(
        id: 25,
        name: "pikachu",
        captureRate: 190,
        colorName: "yellow",
        pokemons: [pikachu, pikachuLibre]
    )

    static let content = PokemonSearchContent(
        keyword: "pika",
        species: [pikachuSpecies],
        hasMorePages: false
    )
}
