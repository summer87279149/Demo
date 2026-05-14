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
        Deferred { [repository] in
            // Bridge the async repository call into Combine while preserving cancellation.
            var task: Task<Void, Never>?
            let future = Future<PokemonSearchPage, Error> { promise in
                task = Task {
                    do {
                        let page = try await repository.searchSpecies(keyword: keyword, limit: limit, offset: offset)
                        guard !Task.isCancelled else { return }
                        promise(.success(page))
                    } catch {
                        guard !Task.isCancelled else { return }
                        promise(.failure(error))
                    }
                }
            }

            return future
                .handleEvents(receiveCancel: {
                    task?.cancel()
                })
        }
        .eraseToAnyPublisher()
    }
}
