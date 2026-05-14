//
//  PokemonRepository.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import Foundation

protocol PokemonRepository {
    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> PokemonSearchPage
}
