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
            totalCount: 1,
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
            .loaded(PokemonSearchContent(species: [species], totalCount: 1))
        )
    }

    func testNewSearchReplacesPreviousResults() async throws {
        let useCase = MockPokemonSearchUseCase()
        let pikachu = PokemonTestFactory.species(id: 25, name: "pikachu")
        let charmander = PokemonTestFactory.species(id: 4, name: "charmander")
        useCase.pagesByKeyword["pika"] = PokemonSearchPage(
            items: [pikachu],
            totalCount: 1,
            limit: 20,
            offset: 0
        )
        useCase.pagesByKeyword["char"] = PokemonSearchPage(
            items: [charmander],
            totalCount: 1,
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
        try await Task.sleep(nanoseconds: 450_000_000)

        XCTAssertEqual(
            viewModel.state,
            .loaded(PokemonSearchContent(species: [charmander], totalCount: 1))
        )
        XCTAssertEqual(useCase.requests.map { $0.keyword }, ["pika", "char"])
    }

    func testPaginationAppendsNextPage() async throws {
        let useCase = MockPokemonSearchUseCase()
        let firstSpecies = PokemonTestFactory.species(id: 1, name: "bulbasaur")
        let secondSpecies = PokemonTestFactory.species(id: 2, name: "ivysaur")
        useCase.pagesByOffset[0] = PokemonSearchPage(
            items: [firstSpecies],
            totalCount: 2,
            limit: 1,
            offset: 0
        )
        useCase.pagesByOffset[1] = PokemonSearchPage(
            items: [secondSpecies],
            totalCount: 2,
            limit: 1,
            offset: 1
        )
        let viewModel = PokemonSearchViewModel(
            dependencyProvider: MockPokemonSearchDependencyProvider(useCase: useCase),
            pageSize: 1
        )

        viewModel.searchText = "saur"
        try await Task.sleep(nanoseconds: 450_000_000)
        viewModel.loadNextPageIfNeeded(currentSpecies: firstSpecies)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(
            viewModel.state,
            .loaded(PokemonSearchContent(species: [firstSpecies, secondSpecies], totalCount: 2))
        )
        XCTAssertEqual(useCase.requests.map { $0.offset }, [0, 1])
        XCTAssertFalse(viewModel.hasMorePages)
    }

    func testNextPageFailureKeepsExistingContentAndRetryRecovers() async throws {
        let useCase = MockPokemonSearchUseCase()
        let firstSpecies = PokemonTestFactory.species(id: 1, name: "bulbasaur")
        let secondSpecies = PokemonTestFactory.species(id: 2, name: "ivysaur")
        let firstPage = PokemonSearchPage(
            items: [firstSpecies],
            totalCount: 2,
            limit: 1,
            offset: 0
        )
        let secondPage = PokemonSearchPage(
            items: [secondSpecies],
            totalCount: 2,
            limit: 1,
            offset: 1
        )
        useCase.pagesByOffset[0] = firstPage
        let viewModel = PokemonSearchViewModel(
            dependencyProvider: MockPokemonSearchDependencyProvider(useCase: useCase),
            pageSize: 1
        )

        viewModel.searchText = "saur"
        try await Task.sleep(nanoseconds: 450_000_000)

        useCase.error = ViewModelTestError.failed
        viewModel.loadNextPageIfNeeded(currentSpecies: firstSpecies)
        try await Task.sleep(nanoseconds: 100_000_000)

        let content = PokemonSearchContent(species: [firstSpecies], totalCount: 2)
        XCTAssertEqual(viewModel.state, .nextPageFailed(content, "Request failed"))

        useCase.error = nil
        useCase.pagesByOffset[1] = secondPage
        viewModel.retryNextPage()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(
            viewModel.state,
            .loaded(PokemonSearchContent(species: [firstSpecies, secondSpecies], totalCount: 2))
        )
        XCTAssertEqual(useCase.requests.map { $0.offset }, [0, 1, 1])
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
            totalCount: 1,
            limit: 20,
            offset: 0
        )
        viewModel.retrySearch()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(
            viewModel.state,
            .loaded(PokemonSearchContent(species: [species], totalCount: 1))
        )
    }
}

private final class MockPokemonSearchUseCase: PokemonSearchUseCaseType {
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
            ?? PokemonSearchPage(items: [], totalCount: 0, limit: limit, offset: offset)

        return Just(page)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

private struct MockPokemonSearchDependencyProvider: PokemonSearchViewModelDependencyProviderType {
    let useCase: PokemonSearchUseCaseType

    var pokemonSearchUseCase: PokemonSearchUseCaseType? {
        useCase
    }
}

private enum ViewModelTestError: LocalizedError {
    case failed

    var errorDescription: String? {
        "Request failed"
    }
}
