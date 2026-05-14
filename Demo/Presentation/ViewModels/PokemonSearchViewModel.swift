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
    var pokemonSearchUseCase: PokemonSearchUseCaseType? { get }
}

extension Dependency: PokemonSearchViewModelDependencyProviderType {
    var pokemonSearchUseCase: PokemonSearchUseCaseType? {
        resolve(PokemonSearchUseCaseType.self)
    }
}

@Observable
final class PokemonSearchViewModel {
    var searchText: String = "" {
        didSet {
            let keyword = sanitizedKeyword(from: searchText)
            if keyword.isEmpty {
                state = .idle
            } else {
                state = .loading
            }
            manualRequestCancellable?.cancel()
            searchTextSubject.send(keyword)
        }
    }

    private(set) var state: PokemonSearchState = .idle

    @ObservationIgnored private let useCase: PokemonSearchUseCaseType?

    @ObservationIgnored private let pageSize: Int

    @ObservationIgnored private let searchTextSubject = PassthroughSubject<String, Never>()

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    @ObservationIgnored private var manualRequestCancellable: AnyCancellable?

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

        loadNextPage(from: content)
    }


    private func loadNextPage(from content: PokemonSearchContent) {
        state = .loadingNextPage(content)
        manualRequestCancellable = searchPublisher(
            keyword: content.keyword,
            offset: content.species.count,
            append: true
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] result in
            self?.apply(result)
        }
    }

    func retrySearch() {
        let keyword = sanitizedKeyword(from: searchText)
        guard !keyword.isEmpty else {
            apply(.empty)
            return
        }

        prepareForNewSearch(keyword: keyword)
        manualRequestCancellable = searchPublisher(keyword: keyword, offset: 0, append: false)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.apply(result)
            }
    }

    private func setupBindings() {
        searchTextSubject
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .map { [weak self] keyword -> AnyPublisher<SearchResult, Never> in
                guard let self else {
                    return Empty().eraseToAnyPublisher()
                }
                guard !keyword.isEmpty else {
                    return Just(.empty).eraseToAnyPublisher()
                }

                self.prepareForNewSearch(keyword: keyword)
                return self.searchPublisher(keyword: keyword, offset: 0, append: false)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.apply(result)
            }
            .store(in: &cancellables)
    }

    private func prepareForNewSearch(keyword: String) {
        state = .loading
        manualRequestCancellable?.cancel()
    }

    private func searchPublisher(keyword: String, offset: Int, append: Bool) -> AnyPublisher<SearchResult, Never> {
        guard let useCase else {
            return Just(
                .failure("Search service is not available.", keyword: keyword, append: append)
            )
            .eraseToAnyPublisher()
        }

        return useCase
            .search(keyword: keyword, limit: pageSize, offset: offset)
            .map { SearchResult.page($0, keyword: keyword, append: append) }
            .catch { error in
                Just(SearchResult.failure(error.localizedDescription, keyword: keyword, append: append))
            }
            .eraseToAnyPublisher()
    }

    private func apply(_ result: SearchResult) {
        switch result {
        case .empty:
            state = .idle
        case .page(let page, let keyword, let append):
            guard keyword == sanitizedKeyword(from: searchText) else { return }

            let previousSpecies = append ? state.content?.species ?? [] : []
            let species = previousSpecies + page.items
            let content = PokemonSearchContent(
                keyword: keyword,
                species: species,
                hasMorePages: page.hasMorePages
            )
            state = .loaded(content)
        case .failure(let message, let keyword, let append):
            guard keyword == sanitizedKeyword(from: searchText) else { return }

            if append, let content = state.content {
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
    case empty
    case page(PokemonSearchPage, keyword: String, append: Bool)
    case failure(String, keyword: String, append: Bool)
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

private extension PokemonSearchState {
    var content: PokemonSearchContent? {
        switch self {
        case .loaded(let content),
             .loadingNextPage(let content):
            return content
        case .idle, .loading, .failed:
            return nil
        }
    }
}
