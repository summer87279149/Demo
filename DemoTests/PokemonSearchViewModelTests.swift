//
//  PokemonSearchViewModelTests.swift
//  DemoTests
//
//  Created by xiatian on 5/14/26.
//

import Combine
import XCTest
@testable import Demo

@MainActor
final class PokemonSearchViewModelTests: XCTestCase {
    func testEmptySearchDoesNotRequestData() async throws {
        let useCase = MockPokemonSearchUseCase()
        let viewModel = PokemonSearchViewModel(
            dependencyProvider: MockPokemonSearchDependencyProvider(useCase: useCase),
            pageSize: 20
        )

        viewModel.searchText = "   "
        try await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertTrue(useCase.requests.isEmpty)
        XCTAssertEqual(viewModel.state, .idle)
    }

    func testDebouncedSearchLoadsResults() async throws {
        let useCase = MockPokemonSearchUseCase()
        let species = PokemonTestFactory.species(id: 25, name: "pikachu")
        useCase.pagesByKeyword["pika"] = PokemonSearchPage(
            items: [species],
            limit: 20,
            offset: 0
        )
        let viewModel = PokemonSearchViewModel(
            dependencyProvider: MockPokemonSearchDependencyProvider(useCase: useCase),
            pageSize: 20
        )

        viewModel.searchText = "pi"
        viewModel.searchText = "pika"
        try await Task.sleep(nanoseconds: 450_000_000)

        XCTAssertEqual(useCase.requests.map { $0.keyword }, ["pika"])
        XCTAssertEqual(
            viewModel.state,
            .loaded(PokemonSearchContent(keyword: "pika", species: [species], hasMorePages: false))
        )
    }

    func testNewSearchReplacesPreviousResults() async throws {
        let useCase = MockPokemonSearchUseCase()
        let pikachu = PokemonTestFactory.species(id: 25, name: "pikachu")
        let charmander = PokemonTestFactory.species(id: 4, name: "charmander")
        useCase.pagesByKeyword["pika"] = PokemonSearchPage(
            items: [pikachu],
            limit: 20,
            offset: 0
        )
        useCase.pagesByKeyword["char"] = PokemonSearchPage(
            items: [charmander],
            limit: 20,
            offset: 0
        )
        let viewModel = PokemonSearchViewModel(
            dependencyProvider: MockPokemonSearchDependencyProvider(useCase: useCase),
            pageSize: 20
        )

        viewModel.searchText = "pika"
        try await Task.sleep(nanoseconds: 450_000_000)
        viewModel.searchText = "char"

        XCTAssertEqual(viewModel.state, .loading)

        try await Task.sleep(nanoseconds: 450_000_000)

        XCTAssertEqual(
            viewModel.state,
            .loaded(PokemonSearchContent(keyword: "char", species: [charmander], hasMorePages: false))
        )
        XCTAssertEqual(useCase.requests.map { $0.keyword }, ["pika", "char"])
    }

    func testPaginationAppendsNextPage() async throws {
        let useCase = MockPokemonSearchUseCase()
        let firstSpecies = PokemonTestFactory.species(id: 1, name: "bulbasaur")
        let secondSpecies = PokemonTestFactory.species(id: 2, name: "ivysaur")
        let thirdSpecies = PokemonTestFactory.species(id: 3, name: "venusaur")
        useCase.pagesByOffset[0] = PokemonSearchPage(
            items: [firstSpecies, secondSpecies],
            limit: 2,
            offset: 0
        )
        useCase.pagesByOffset[2] = PokemonSearchPage(
            items: [thirdSpecies],
            limit: 2,
            offset: 2
        )
        let viewModel = PokemonSearchViewModel(
            dependencyProvider: MockPokemonSearchDependencyProvider(useCase: useCase),
            pageSize: 2
        )

        viewModel.searchText = "saur"
        try await Task.sleep(nanoseconds: 450_000_000)
        viewModel.loadNextPageIfNeeded(currentSpecies: secondSpecies)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(
            viewModel.state,
            .loaded(PokemonSearchContent(keyword: "saur", species: [firstSpecies, secondSpecies, thirdSpecies], hasMorePages: false))
        )
        XCTAssertEqual(useCase.requests.map { $0.offset }, [0, 2])
        if case .loaded(let content) = viewModel.state {
            XCTAssertFalse(content.hasMorePages)
        } else {
            XCTFail("Expected loaded state after pagination.")
        }
    }

    func testNextPageFailureKeepsExistingContentAndRetryRecovers() async throws {
        let useCase = MockPokemonSearchUseCase()
        let firstSpecies = PokemonTestFactory.species(id: 1, name: "bulbasaur")
        let secondSpecies = PokemonTestFactory.species(id: 2, name: "ivysaur")
        let thirdSpecies = PokemonTestFactory.species(id: 3, name: "venusaur")
        let firstPage = PokemonSearchPage(
            items: [firstSpecies, secondSpecies],
            limit: 2,
            offset: 0
        )
        let secondPage = PokemonSearchPage(
            items: [thirdSpecies],
            limit: 2,
            offset: 2
        )
        useCase.pagesByOffset[0] = firstPage
        let viewModel = PokemonSearchViewModel(
            dependencyProvider: MockPokemonSearchDependencyProvider(useCase: useCase),
            pageSize: 2
        )

        viewModel.searchText = "saur"
        try await Task.sleep(nanoseconds: 450_000_000)

        useCase.error = ViewModelTestError.failed
        viewModel.loadNextPageIfNeeded(currentSpecies: secondSpecies)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(
            viewModel.state,
            .loaded(PokemonSearchContent(keyword: "saur", species: [firstSpecies, secondSpecies], hasMorePages: true))
        )

        useCase.error = nil
        useCase.pagesByOffset[2] = secondPage
        viewModel.loadNextPageIfNeeded(currentSpecies: secondSpecies)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(
            viewModel.state,
            .loaded(PokemonSearchContent(keyword: "saur", species: [firstSpecies, secondSpecies, thirdSpecies], hasMorePages: false))
        )
        XCTAssertEqual(useCase.requests.map { $0.offset }, [0, 2, 2])
    }

    func testErrorStateCanRecoverWithRetry() async throws {
        let useCase = MockPokemonSearchUseCase()
        useCase.error = ViewModelTestError.failed
        let viewModel = PokemonSearchViewModel(
            dependencyProvider: MockPokemonSearchDependencyProvider(useCase: useCase),
            pageSize: 20
        )

        viewModel.searchText = "pika"
        try await Task.sleep(nanoseconds: 450_000_000)

        XCTAssertEqual(viewModel.state, .failed("Request failed"))

        let species = PokemonTestFactory.species(id: 25, name: "pikachu")
        useCase.error = nil
        useCase.pagesByKeyword["pika"] = PokemonSearchPage(
            items: [species],
            limit: 20,
            offset: 0
        )
        viewModel.retrySearch()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(
            viewModel.state,
            .loaded(PokemonSearchContent(keyword: "pika", species: [species], hasMorePages: false))
        )
    }
}

private final class MockPokemonSearchUseCase: SearchPokemonSpeciesUseCase {
    var requests: [(keyword: String, limit: Int, offset: Int)] = []
    var pagesByKeyword: [String: PokemonSearchPage] = [:]
    var pagesByOffset: [Int: PokemonSearchPage] = [:]
    var error: Error?

    func search(keyword: String, limit: Int, offset: Int) -> AnyPublisher<PokemonSearchPage, Error> {
        requests.append((keyword, limit, offset))

        if let error {
            return Fail(error: error).eraseToAnyPublisher()
        }

        let page = pagesByOffset[offset]
            ?? pagesByKeyword[keyword]
            ?? PokemonSearchPage(items: [], limit: limit, offset: offset)

        return Just(page)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

private struct MockPokemonSearchDependencyProvider: PokemonSearchViewModelDependencyProviderType {
    let useCase: SearchPokemonSpeciesUseCase

    var pokemonSearchUseCase: SearchPokemonSpeciesUseCase? {
        useCase
    }
}

private enum ViewModelTestError: LocalizedError {
    case failed

    var errorDescription: String? {
        "Request failed"
    }
}
