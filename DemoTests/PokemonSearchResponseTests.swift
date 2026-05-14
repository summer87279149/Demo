//
//  PokemonSearchResponseTests.swift
//  DemoTests
//
//  Created by xiatian on 5/14/26.
//

import XCTest
@testable import Demo

final class PokemonSearchResponseTests: XCTestCase {
    func testDecodeGraphQLResponseMapsSpeciesAndPokemonAbilities() throws {
        let data = """
        {
          "data": {
            "pokemon_v2_pokemonspecies_aggregate": {
              "aggregate": {
                "count": 1
              }
            },
            "pokemon_v2_pokemonspecies": [
              {
                "id": 25,
                "name": "pikachu",
                "capture_rate": 190,
                "pokemon_v2_pokemoncolor": {
                  "name": "yellow"
                },
                "pokemon_v2_pokemons": [
                  {
                    "id": 25,
                    "name": "pikachu",
                    "pokemon_v2_pokemonabilities": [
                      {
                        "pokemon_v2_ability": {
                          "name": "static"
                        }
                      },
                      {
                        "pokemon_v2_ability": {
                          "name": "lightning-rod"
                        }
                      }
                    ]
                  }
                ]
              }
            ]
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(
            GraphQLResponse<PokemonSpeciesSearchPayload>.self,
            from: data
        )
        let page = try XCTUnwrap(response.data?.toDomain(limit: 20, offset: 0))

        XCTAssertEqual(page.totalCount, 1)
        XCTAssertEqual(page.limit, 20)
        XCTAssertEqual(page.offset, 0)
        XCTAssertEqual(page.items.first?.name, "pikachu")
        XCTAssertEqual(page.items.first?.captureRate, 190)
        XCTAssertEqual(page.items.first?.colorName, "yellow")
        XCTAssertEqual(page.items.first?.pokemons.first?.name, "pikachu")
        XCTAssertEqual(page.items.first?.pokemons.first?.abilities, ["static", "lightning-rod"])
    }
}
