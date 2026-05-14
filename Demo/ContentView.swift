//
//  ContentView.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var searchViewModel = PokemonSearchViewModel()

    var body: some View {
        if hasSeenWelcome {
            PokemonSearchView(viewModel: searchViewModel)
        } else {
            WelcomeView {
                hasSeenWelcome = true
            }
        }
    }
}
