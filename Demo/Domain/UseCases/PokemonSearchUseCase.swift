//
//  PokemonSearchUseCase.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import Combine
import Foundation

protocol PokemonSearchUseCaseType {
    func search(keyword: String, limit: Int, offset: Int) -> AnyPublisher<PokemonSearchPage, Error>
}

final class PokemonSearchUseCase: PokemonSearchUseCaseType {
    private let repository: PokemonRepositoryType

    init(repository: PokemonRepositoryType) {
        self.repository = repository
    }

    func search(keyword: String, limit: Int, offset: Int) -> AnyPublisher<PokemonSearchPage, Error> {
        repository.searchSpecies(keyword: keyword, limit: limit, offset: offset)
    }
}
