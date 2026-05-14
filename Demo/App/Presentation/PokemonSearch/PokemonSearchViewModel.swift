//
//  PokemonSearchViewModel.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import Combine
import Foundation
import Observation

protocol PokemonSearchViewModelDependencyProviderType {
    var pokemonSearchUseCase: SearchPokemonSpeciesUseCase { get }
}

extension Dependency: PokemonSearchViewModelDependencyProviderType {
    var pokemonSearchUseCase: SearchPokemonSpeciesUseCase {
        resolveRequired(SearchPokemonSpeciesUseCase.self)
    }
}

@Observable
final class PokemonSearchViewModel {
    private(set) var state: PokemonSearchState = .idle
    var searchText: String = "" {
        didSet {
            actionSubject.send(.textChange(searchText))
        }
    }
    @ObservationIgnored private let useCase: SearchPokemonSpeciesUseCase
    @ObservationIgnored private let pageSize: Int
    @ObservationIgnored private let actionSubject = PassthroughSubject<SearchAction, Never>()
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    init(
        dependencyProvider: PokemonSearchViewModelDependencyProviderType = Dependency.shared,
        pageSize: Int = 20
    ) {
        self.useCase = dependencyProvider.pokemonSearchUseCase
        self.pageSize = pageSize
        setupBindings()
    }

    func loadNextPageIfNeeded(currentSpecies: PokemonSpecies) {
        guard case .loaded(let content) = state else { return }
        guard currentSpecies.id == content.species.last?.id else { return }
        guard content.hasMorePages else { return }
        actionSubject.send(.loadMore)
    }

    func retrySearch() {
        actionSubject.send(.retry)
    }

    private func setupBindings() {
        let actions = actionSubject.share()

        let textRequests = actions
            .compactMap { [weak self] action -> String? in
                guard case .textChange(let text) = action else { return nil }
                return self?.sanitizedKeyword(from: text)
            }
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] keyword in
                self?.prepareForTextChange(keyword)
            })
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .compactMap { keyword -> SearchRequest? in
                guard !keyword.isEmpty else { return nil }
                return SearchRequest(keyword: keyword, offset: 0, mode: .firstPage)
            }
            .eraseToAnyPublisher()

        let loadMoreRequests = actions
            .compactMap { [weak self] action -> SearchRequest? in
                guard case .loadMore = action else { return nil }
                return self?.makeLoadMoreRequest()
            }
            .eraseToAnyPublisher()

        let retryRequests = actions
            .compactMap { [weak self] action -> SearchRequest? in
                guard case .retry = action else { return nil }
                return self?.makeRetryRequest()
            }
            .eraseToAnyPublisher()

        Publishers.Merge3(textRequests, loadMoreRequests, retryRequests)
            .map { [weak self] request -> AnyPublisher<SearchResult, Never> in
                guard let self else {
                    return Empty().eraseToAnyPublisher()
                }
                return self.searchPublisher(for: request)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.apply(result)
            }
            .store(in: &cancellables)
    }

    private func prepareForTextChange(_ keyword: String) {
        state = keyword.isEmpty ? .idle : .loading
    }

    private func makeLoadMoreRequest() -> SearchRequest? {
        guard case .loaded(let content) = state else { return nil }
        guard content.hasMorePages else { return nil }

        state = .loadingNextPage(content)
        return SearchRequest(
            keyword: content.keyword,
            offset: content.species.count,
            mode: .nextPage(existingContent: content)
        )
    }

    private func makeRetryRequest() -> SearchRequest? {
        let keyword = sanitizedKeyword(from: searchText)
        guard !keyword.isEmpty else {
            state = .idle
            return nil
        }

        state = .loading
        return SearchRequest(keyword: keyword, offset: 0, mode: .firstPage)
    }

    private func searchPublisher(for request: SearchRequest) -> AnyPublisher<SearchResult, Never> {
        return useCase
            .search(keyword: request.keyword, limit: pageSize, offset: request.offset)
            .map { SearchResult.page($0, request: request) }
            .catch { error in
                Just(SearchResult.failure(error.localizedDescription, request: request))
            }
            .eraseToAnyPublisher()
    }

    private func apply(_ result: SearchResult) {
        switch result {
        case .page(let page, let request):
            guard request.keyword == sanitizedKeyword(from: searchText) else { return }
            let previousSpecies = request.mode.existingContent?.species ?? []
            let species = previousSpecies + page.items
            let content = PokemonSearchContent(
                keyword: request.keyword,
                species: species,
                hasMorePages: page.hasMorePages
            )
            state = .loaded(content)

        case .failure(let message, let request):
            guard request.keyword == sanitizedKeyword(from: searchText) else { return }

            if let content = request.mode.existingContent {
                state = .loaded(content)
            } else {
                state = .failed(message)
            }
        }
    }

    private func sanitizedKeyword(from text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum SearchResult {
    case page(PokemonSearchPage, request: SearchRequest)
    case failure(String, request: SearchRequest)
}

private enum SearchAction {
    case textChange(String)
    case loadMore
    case retry
}

private struct SearchRequest {
    let keyword: String
    let offset: Int
    let mode: SearchMode
}

private enum SearchMode {
    case firstPage
    case nextPage(existingContent: PokemonSearchContent)

    var existingContent: PokemonSearchContent? {
        switch self {
        case .firstPage:
            return nil
        case .nextPage(let content):
            return content
        }
    }
}

struct PokemonSearchContent: Equatable {
    let keyword: String
    let species: [PokemonSpecies]
    let hasMorePages: Bool
}

enum PokemonSearchState: Equatable {
    case idle
    case loading
    case loaded(PokemonSearchContent)
    case loadingNextPage(PokemonSearchContent)
    case failed(String)
}
