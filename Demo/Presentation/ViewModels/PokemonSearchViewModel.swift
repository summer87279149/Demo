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
            if sanitizedKeyword(from: searchText).isEmpty {
                state = .idle
                currentKeyword = ""
                paginationCancellable?.cancel()
                retryCancellable?.cancel()
            }
            searchTextSubject.send(searchText)
        }
    }
    private(set) var state: PokemonSearchState = .idle

    var hasMorePages: Bool {
        state.content?.hasMorePages ?? false
    }

    @ObservationIgnored private let dependencyProvider: PokemonSearchViewModelDependencyProviderType
    @ObservationIgnored private let pageSize: Int
    @ObservationIgnored private let searchTextSubject = PassthroughSubject<String, Never>()
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var paginationCancellable: AnyCancellable?
    @ObservationIgnored private var retryCancellable: AnyCancellable?
    @ObservationIgnored private var currentKeyword = ""

    init(
        dependencyProvider: PokemonSearchViewModelDependencyProviderType = Dependency.shared,
        pageSize: Int = 20
    ) {
        self.dependencyProvider = dependencyProvider
        self.pageSize = pageSize
        setupBindings()
    }

    func loadNextPageIfNeeded(currentSpecies: PokemonSpecies) {
        guard case .loaded(let content) = state else { return }
        guard currentSpecies.id == content.species.last?.id else { return }
        guard content.hasMorePages, !currentKeyword.isEmpty else { return }

        loadNextPage(from: content)
    }

    func retryNextPage() {
        guard case .nextPageFailed(let content, _) = state else { return }
        guard content.hasMorePages, !currentKeyword.isEmpty else { return }

        loadNextPage(from: content)
    }

    private func loadNextPage(from content: PokemonSearchContent) {
        state = .loadingNextPage(content)
        paginationCancellable = searchPublisher(
            keyword: currentKeyword,
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
        retryCancellable = searchPublisher(keyword: keyword, offset: 0, append: false)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.apply(result)
            }
    }

    private func setupBindings() {
        searchTextSubject
            .map { [weak self] in self?.sanitizedKeyword(from: $0) ?? "" }
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
        currentKeyword = keyword
        state = .loading
        paginationCancellable?.cancel()
        retryCancellable?.cancel()
    }

    private func searchPublisher(keyword: String, offset: Int, append: Bool) -> AnyPublisher<SearchResult, Never> {
        guard let useCase = dependencyProvider.pokemonSearchUseCase else {
            return Just(.failure("Search service is not available.", append: append)).eraseToAnyPublisher()
        }

        return useCase
            .search(keyword: keyword, limit: pageSize, offset: offset)
            .map { SearchResult.page($0, append: append) }
            .catch { error in
                Just(SearchResult.failure(error.localizedDescription, append: append))
            }
            .eraseToAnyPublisher()
    }

    private func apply(_ result: SearchResult) {
        switch result {
        case .empty:
            currentKeyword = ""
            state = .idle
        case .page(let page, let append):
            let previousSpecies = append ? state.content?.species ?? [] : []
            let species = previousSpecies + page.items
            let content = PokemonSearchContent(
                species: species,
                totalCount: page.totalCount
            )
            state = .loaded(content)
        case .failure(let message, let append):
            if append, let content = state.content {
                state = .nextPageFailed(content, message)
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
    case page(PokemonSearchPage, append: Bool)
    case failure(String, append: Bool)
}

struct PokemonSearchContent: Equatable {
    let species: [PokemonSpecies]
    let totalCount: Int

    var hasMorePages: Bool {
        species.count < totalCount
    }
}

enum PokemonSearchState: Equatable {
    case idle
    case loading
    case loaded(PokemonSearchContent)
    case loadingNextPage(PokemonSearchContent)
    case failed(String)
    case nextPageFailed(PokemonSearchContent, String)
}

private extension PokemonSearchState {
    var content: PokemonSearchContent? {
        switch self {
        case .loaded(let content),
             .loadingNextPage(let content),
             .nextPageFailed(let content, _):
            return content
        case .idle, .loading, .failed:
            return nil
        }
    }
}
