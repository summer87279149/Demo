//
//  Pokemon.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import Foundation

struct Pokemon: Identifiable, Hashable {
    let id: Int
    let name: String
    let abilities: [String]
}
