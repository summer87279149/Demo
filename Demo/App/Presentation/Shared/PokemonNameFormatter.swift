//
//  PokemonNameFormatter.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import Foundation

enum PokemonNameFormatter {
    static func displayName(_ name: String) -> String {
        name
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}
