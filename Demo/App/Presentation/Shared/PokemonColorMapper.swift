//
//  PokemonColorMapper.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import SwiftUI

enum PokemonColorMapper {
    static func backgroundColor(for colorName: String) -> Color {
        switch colorName.lowercased() {
        case "black":
            return Color(red: 0.12, green: 0.13, blue: 0.15)
        case "blue":
            return Color(red: 0.78, green: 0.88, blue: 1.0)
        case "brown":
            return Color(red: 0.76, green: 0.61, blue: 0.46)
        case "gray":
            return Color(red: 0.84, green: 0.86, blue: 0.88)
        case "green":
            return Color(red: 0.75, green: 0.91, blue: 0.78)
        case "pink":
            return Color(red: 1.0, green: 0.82, blue: 0.90)
        case "purple":
            return Color(red: 0.86, green: 0.80, blue: 0.96)
        case "red":
            return Color(red: 1.0, green: 0.80, blue: 0.78)
        case "white":
            return Color(red: 0.96, green: 0.96, blue: 0.94)
        case "yellow":
            return Color(red: 1.0, green: 0.92, blue: 0.50)
        default:
            return Color(red: 0.88, green: 0.90, blue: 0.92)
        }
    }

    static func foregroundColor(for colorName: String) -> Color {
        colorName.lowercased() == "black" ? .white : .primary
    }
}
