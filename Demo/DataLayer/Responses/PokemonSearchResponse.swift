//
//  PokemonSearchResponse.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import Foundation

struct GraphQLResponse<Payload: Decodable>: Decodable {
    let data: Payload?
    let errors: [GraphQLError]?
}

struct GraphQLError: Decodable, Equatable {
    let message: String
}

struct PokemonSpeciesSearchPayload: Decodable, Equatable {
    let pokemonV2PokemonspeciesAggregate: PokemonSpeciesAggregate
    let pokemonV2Pokemonspecies: [PokemonSpeciesResponse]

    enum CodingKeys: String, CodingKey {
        case pokemonV2PokemonspeciesAggregate = "pokemon_v2_pokemonspecies_aggregate"
        case pokemonV2Pokemonspecies = "pokemon_v2_pokemonspecies"
    }
}

struct PokemonSpeciesAggregate: Decodable, Equatable {
    let aggregate: PokemonSpeciesAggregateCount?
}

struct PokemonSpeciesAggregateCount: Decodable, Equatable {
    let count: Int
}

struct PokemonSpeciesResponse: Decodable, Equatable {
    let id: Int
    let name: String
    let captureRate: Int?
    let pokemonV2Pokemoncolor: PokemonColorResponse?
    let pokemonV2Pokemons: [PokemonResponse]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case captureRate = "capture_rate"
        case pokemonV2Pokemoncolor = "pokemon_v2_pokemoncolor"
        case pokemonV2Pokemons = "pokemon_v2_pokemons"
    }
}

struct PokemonColorResponse: Decodable, Equatable {
    let name: String
}

struct PokemonResponse: Decodable, Equatable {
    let id: Int
    let name: String
    let pokemonV2Pokemonabilities: [PokemonAbilitySlotResponse]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case pokemonV2Pokemonabilities = "pokemon_v2_pokemonabilities"
    }
}

struct PokemonAbilitySlotResponse: Decodable, Equatable {
    let pokemonV2Ability: PokemonAbilityResponse?

    enum CodingKeys: String, CodingKey {
        case pokemonV2Ability = "pokemon_v2_ability"
    }
}

struct PokemonAbilityResponse: Decodable, Equatable {
    let name: String
}

extension PokemonSpeciesSearchPayload {
    func toDomain(limit: Int, offset: Int) -> PokemonSearchPage {
        PokemonSearchPage(
            items: pokemonV2Pokemonspecies.map { $0.toDomain() },
            totalCount: pokemonV2PokemonspeciesAggregate.aggregate?.count ?? 0,
            limit: limit,
            offset: offset
        )
    }
}

private extension PokemonSpeciesResponse {
    func toDomain() -> PokemonSpecies {
        PokemonSpecies(
            id: id,
            name: name,
            captureRate: captureRate ?? 0,
            colorName: pokemonV2Pokemoncolor?.name ?? "gray",
            pokemons: pokemonV2Pokemons.map { $0.toDomain() }
        )
    }
}

private extension PokemonResponse {
    func toDomain() -> Pokemon {
        Pokemon(
            id: id,
            name: name,
            abilities: pokemonV2Pokemonabilities.compactMap(\.pokemonV2Ability?.name)
        )
    }
}
