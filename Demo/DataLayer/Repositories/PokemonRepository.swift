//
//  PokemonRepository.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import Combine
import Foundation

protocol PokemonRepositoryType {
    func searchSpecies(keyword: String, limit: Int, offset: Int) -> AnyPublisher<PokemonSearchPage, Error>
}

final class PokemonRepository: PokemonRepositoryType {
    private let endpoint: URL
    private let networkService: NetworkServiceType
    private let encoder: JSONEncoder

    init(
        endpoint: URL = URL(string: "https://beta.pokeapi.co/graphql/v1beta")!,
        networkService: NetworkServiceType = NetworkService(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.endpoint = endpoint
        self.networkService = networkService
        self.encoder = encoder
    }

    func searchSpecies(keyword: String, limit: Int, offset: Int) -> AnyPublisher<PokemonSearchPage, Error> {
        do {
            let request = try makeSearchRequest(keyword: keyword, limit: limit, offset: offset)
            return networkService
                .request(request)
                .tryMap { (response: GraphQLResponse<PokemonSpeciesSearchPayload>) in
                    if let errors = response.errors, !errors.isEmpty {
                        throw PokemonRepositoryError.graphQL(errors.map(\.message).joined(separator: "\n"))
                    }
                    guard let payload = response.data else {
                        throw PokemonRepositoryError.missingData
                    }
                    return payload.toDomain(limit: limit, offset: offset)
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private func makeSearchRequest(keyword: String, limit: Int, offset: Int) throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(
            GraphQLRequest(
                query: Self.searchQuery,
                variables: GraphQLVariables(
                    search: "%\(keyword)%",
                    limit: limit,
                    offset: offset
                )
            )
        )
        return request
    }

    private static let searchQuery = """
    query SearchPokemonSpecies($search: String!, $limit: Int!, $offset: Int!) {
      pokemon_v2_pokemonspecies_aggregate(where: { name: { _ilike: $search } }) {
        aggregate {
          count
        }
      }
      pokemon_v2_pokemonspecies(
        where: { name: { _ilike: $search } }
        limit: $limit
        offset: $offset
        order_by: { name: asc }
      ) {
        id
        name
        capture_rate
        pokemon_v2_pokemoncolor {
          name
        }
        pokemon_v2_pokemons(order_by: { name: asc }) {
          id
          name
          pokemon_v2_pokemonabilities(order_by: { slot: asc }) {
            pokemon_v2_ability {
              name
            }
          }
        }
      }
    }
    """
}

struct GraphQLRequest: Encodable {
    let query: String
    let variables: GraphQLVariables
}

struct GraphQLVariables: Encodable {
    let search: String
    let limit: Int
    let offset: Int
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
