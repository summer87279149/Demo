//
//  PokemonSearchUseCaseTests.swift
//  DemoTests
//
//  Created by xiatian on 5/14/26.
//

import Combine
import XCTest
@testable import Demo

@MainActor
final class PokemonSearchUseCaseTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables = []
        super.tearDown()
    }

    func testSearchDelegatesToRepository() async throws {
        let expectedPage = PokemonSearchPage(
            items: [PokemonTestFactory.species(id: 25, name: "pikachu")],
            limit: 20,
            offset: 0
        )
        let repository = MockPokemonRepository()
        repository.page = expectedPage
        let useCase = DefaultSearchPokemonSpeciesUseCase(repository: repository)

        var values = useCase
            .search(keyword: "pika", limit: 20, offset: 0)
            .values
            .makeAsyncIterator()
        let receivedPage = try await values.next()

        XCTAssertEqual(repository.requests.count, 1)
        XCTAssertEqual(repository.requests.first?.keyword, "pika")
        XCTAssertEqual(repository.requests.first?.limit, 20)
        XCTAssertEqual(repository.requests.first?.offset, 0)
        XCTAssertEqual(receivedPage, expectedPage)
    }
}

final class MockPokemonRepository: PokemonRepository {
    var requests: [(keyword: String, limit: Int, offset: Int)] = []
    var page = PokemonSearchPage(items: [], limit: 20, offset: 0)
    var error: Error?

    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> PokemonSearchPage {
        requests.append((keyword, limit, offset))

        if let error {
            throw error
        }

        return page
    }
}
