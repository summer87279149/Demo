//
//  ContentView.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
        if hasSeenWelcome {
            PokemonSearchView()
        } else {
            WelcomeView {
                hasSeenWelcome = true
            }
        }
    }
}
