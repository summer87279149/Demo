//
//  PokemonRepositoryTests.swift
//  DemoTests
//
//  Created by xiatian on 5/14/26.
//

import Combine
import XCTest
@testable import Demo

final class PokemonRepositoryTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables = []
        super.tearDown()
    }

    func testSearchSpeciesForwardsParametersToGraphQLClientAndReturnsPage() {
        let graphQLClient = MockPokemonGraphQLClient()
        graphQLClient.page = PokemonSearchPage(
            items: [
                PokemonSpecies(
                    id: 1,
                    name: "bulbasaur",
                    captureRate: 45,
                    colorName: "green",
                    pokemons: [
                        Pokemon(id: 1, name: "bulbasaur", abilities: ["overgrow"])
                    ]
                )
            ],
            limit: 20,
            offset: 40
        )

        let repository = PokemonRepository(graphQLClient: graphQLClient)
        let expectation = expectation(description: "Repository returns mapped page")
        var receivedPage: PokemonSearchPage?

        repository.searchSpecies(keyword: "bulb", limit: 20, offset: 40)
            .sink { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected error: \(error)")
                }
            } receiveValue: { page in
                receivedPage = page
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(graphQLClient.receivedKeyword, "bulb")
        XCTAssertEqual(graphQLClient.receivedLimit, 20)
        XCTAssertEqual(graphQLClient.receivedOffset, 40)
        XCTAssertEqual(receivedPage?.items.first?.name, "bulbasaur")
        XCTAssertEqual(receivedPage?.items.first?.pokemons.first?.abilities, ["overgrow"])
    }
}

private final class MockPokemonGraphQLClient: PokemonGraphQLClientType {
    var receivedKeyword: String?
    var receivedLimit: Int?
    var receivedOffset: Int?
    var page: PokemonSearchPage?
    var error: Error?

    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> PokemonSearchPage {
        receivedKeyword = keyword
        receivedLimit = limit
        receivedOffset = offset

        if let error {
            throw error
        }

        guard let page else {
            throw TestError.missingPage
        }

        return page
    }
}

private enum TestError: Error {
    case missingPage
}
