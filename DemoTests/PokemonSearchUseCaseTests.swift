//
//  PokemonSearchUseCaseTests.swift
//  DemoTests
//
//  Created by xiatian on 5/14/26.
//

import Combine
import XCTest
@testable import Demo

final class PokemonSearchUseCaseTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables = []
        super.tearDown()
    }

    func testSearchDelegatesToRepository() {
        let expectedPage = PokemonSearchPage(
            items: [PokemonTestFactory.species(id: 25, name: "pikachu")],
            limit: 20,
            offset: 0
        )
        let repository = MockPokemonRepository()
        repository.page = expectedPage
        let useCase = PokemonSearchUseCase(repository: repository)

        let expectation = expectation(description: "Use case returns repository page")
        var receivedPage: PokemonSearchPage?
        useCase.search(keyword: "pika", limit: 20, offset: 0)
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

        XCTAssertEqual(repository.requests.count, 1)
        XCTAssertEqual(repository.requests.first?.keyword, "pika")
        XCTAssertEqual(repository.requests.first?.limit, 20)
        XCTAssertEqual(repository.requests.first?.offset, 0)
        XCTAssertEqual(receivedPage, expectedPage)
    }
}

final class MockPokemonRepository: PokemonRepositoryType {
    var requests: [(keyword: String, limit: Int, offset: Int)] = []
    var page = PokemonSearchPage(items: [], limit: 20, offset: 0)
    var error: Error?

    func searchSpecies(keyword: String, limit: Int, offset: Int) -> AnyPublisher<PokemonSearchPage, Error> {
        requests.append((keyword, limit, offset))

        if let error {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return Just(page)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
