//
//  SearchPokemonSpeciesUseCase.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import Combine
import Foundation

protocol SearchPokemonSpeciesUseCase {
    func search(keyword: String, limit: Int, offset: Int) -> AnyPublisher<PokemonSearchPage, Error>
}

final class DefaultSearchPokemonSpeciesUseCase: SearchPokemonSpeciesUseCase {
    private let repository: PokemonRepository

    init(repository: PokemonRepository) {
        self.repository = repository
    }

    func search(keyword: String, limit: Int, offset: Int) -> AnyPublisher<PokemonSearchPage, Error> {
        Future<PokemonSearchPage, Error> { [repository] promise in
            Task {
                do {
                    let page = try await repository.searchSpecies(keyword: keyword, limit: limit, offset: offset)
                    promise(.success(page))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
