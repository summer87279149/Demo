//
//  DemoApp.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import SwiftUI

@main
struct DemoApp: App {
    init() {
        Dependency.shared.register(PokemonRepository.self) { _ in
            DefaultPokemonRepository()
        }
        Dependency.shared.register(SearchPokemonSpeciesUseCase.self) { resolver in
            DefaultSearchPokemonSpeciesUseCase(
                repository: resolver.resolve(PokemonRepository.self) ?? DefaultPokemonRepository()
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
