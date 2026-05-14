//
//  DefaultPokemonRepository.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import Apollo
import Foundation

final class DefaultPokemonRepository: PokemonRepository {
    private let client: ApolloClient

    init(client: ApolloClient = ApolloClient(url: URL(string: "https://beta.pokeapi.co/graphql/v1beta")!)) {
        self.client = client
    }

    func searchSpecies(
        keyword: String,
        limit: Int,
        offset: Int
    ) async throws -> PokemonSearchPage {
        let response = try await client.fetch(
            query: PokemonAPI.SearchPokemonSpeciesQuery(
                search: "%\(keyword)%",
                limit: Int32(limit),
                offset: Int32(offset)
            ),
            cachePolicy: .networkOnly
        )

        if let errors = response.errors, !errors.isEmpty {
            let message = errors.compactMap(\.message).joined(separator: "\n")
            throw PokemonRepositoryError.graphQL(message.isEmpty ? "GraphQL request failed." : message)
        }

        guard let data = response.data else {
            throw PokemonRepositoryError.missingData
        }

        return data.toDomain(limit: limit, offset: offset)
    }
}

enum PokemonRepositoryError: LocalizedError, Equatable {
    case graphQL(String)
    case missingData

    var errorDescription: String? {
        switch self {
        case .graphQL(let message):
            return message
        case .missingData:
            return "The server response did not include data."
        }
    }
}

private extension PokemonAPI.SearchPokemonSpeciesQuery.Data {
    func toDomain(limit: Int, offset: Int) -> PokemonSearchPage {
        PokemonSearchPage(
            items: pokemon_v2_pokemonspecies.map { $0.toDomain() },
            limit: limit,
            offset: offset
        )
    }
}

private extension PokemonAPI.SearchPokemonSpeciesQuery.Data.Pokemon_v2_pokemonspecy {
    func toDomain() -> PokemonSpecies {
        PokemonSpecies(
            id: id,
            name: name,
            captureRate: capture_rate ?? 0,
            colorName: pokemon_v2_pokemoncolor?.name ?? "gray",
            pokemons: pokemon_v2_pokemons.map { $0.toDomain() }
        )
    }
}

private extension PokemonAPI.SearchPokemonSpeciesQuery.Data.Pokemon_v2_pokemonspecy.Pokemon_v2_pokemon {
    func toDomain() -> Pokemon {
        Pokemon(
            id: id,
            name: name,
            abilities: pokemon_v2_pokemonabilities.compactMap(\.pokemon_v2_ability?.name)
        )
    }
}
