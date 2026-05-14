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

    func testSearchSpeciesBuildsGraphQLRequestAndMapsResponse() throws {
        let networkService = MockNetworkService()
        let payload = PokemonSpeciesSearchPayload(
            pokemonV2PokemonspeciesAggregate: PokemonSpeciesAggregate(
                aggregate: PokemonSpeciesAggregateCount(count: 1)
            ),
            pokemonV2Pokemonspecies: [
                PokemonSpeciesResponse(
                    id: 1,
                    name: "bulbasaur",
                    captureRate: 45,
                    pokemonV2Pokemoncolor: PokemonColorResponse(name: "green"),
                    pokemonV2Pokemons: [
                        PokemonResponse(
                            id: 1,
                            name: "bulbasaur",
                            pokemonV2Pokemonabilities: [
                                PokemonAbilitySlotResponse(
                                    pokemonV2Ability: PokemonAbilityResponse(name: "overgrow")
                                )
                            ]
                        )
                    ]
                )
            ]
        )
        networkService.response = GraphQLResponse<PokemonSpeciesSearchPayload>(data: payload, errors: nil)

        let repository = PokemonRepository(
            endpoint: URL(string: "https://example.com/graphql")!,
            networkService: networkService
        )

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

        let request = try XCTUnwrap(networkService.receivedRequest)
        XCTAssertEqual(request.url?.absoluteString, "https://example.com/graphql")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(request.httpBody)
        let graphQLRequest = try JSONDecoder().decode(CapturedGraphQLRequest.self, from: body)
        XCTAssertTrue(graphQLRequest.query.contains("pokemon_v2_pokemonspecies"))
        XCTAssertEqual(graphQLRequest.variables.search, "%bulb%")
        XCTAssertEqual(graphQLRequest.variables.limit, 20)
        XCTAssertEqual(graphQLRequest.variables.offset, 40)

        XCTAssertEqual(receivedPage?.totalCount, 1)
        XCTAssertEqual(receivedPage?.items.first?.name, "bulbasaur")
        XCTAssertEqual(receivedPage?.items.first?.pokemons.first?.abilities, ["overgrow"])
    }
}

private final class MockNetworkService: NetworkServiceType {
    var receivedRequest: URLRequest?
    var response: Any?
    var error: Error?

    func request<Response: Decodable>(_ request: URLRequest) -> AnyPublisher<Response, Error> {
        receivedRequest = request

        if let error {
            return Fail(error: error).eraseToAnyPublisher()
        }

        guard let response = response as? Response else {
            return Fail(error: TestError.missingResponse).eraseToAnyPublisher()
        }

        return Just(response)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

private struct CapturedGraphQLRequest: Decodable {
    let query: String
    let variables: CapturedGraphQLVariables
}

private struct CapturedGraphQLVariables: Decodable {
    let search: String
    let limit: Int
    let offset: Int
}

private enum TestError: Error {
    case missingResponse
}
