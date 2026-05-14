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
        Dependency.shared.register(NetworkServiceType.self) { _ in
            NetworkService()
        }
        Dependency.shared.register(PokemonRepositoryType.self) { resolver in
            PokemonRepository(
                networkService: resolver.resolve(NetworkServiceType.self) ?? NetworkService()
            )
        }
        Dependency.shared.register(PokemonSearchUseCaseType.self) { resolver in
            PokemonSearchUseCase(
                repository: resolver.resolve(PokemonRepositoryType.self) ?? PokemonRepository()
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
