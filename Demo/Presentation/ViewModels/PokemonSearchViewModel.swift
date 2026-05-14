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
            searchTextSubject.send(searchText)
        }
    }
    var species: [PokemonSpecies] = []
    var isLoading = false
    var isLoadingNextPage = false
    var errorMessage: String?
    var totalCount = 0

    var hasMorePages: Bool {
        !species.isEmpty && species.count < totalCount
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
        guard currentSpecies.id == species.last?.id else { return }
        guard hasMorePages, !isLoading, !isLoadingNextPage, !currentKeyword.isEmpty else { return }

        isLoadingNextPage = true
        errorMessage = nil

        paginationCancellable = searchPublisher(
            keyword: currentKeyword,
            offset: species.count,
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
        species = []
        totalCount = 0
        isLoading = true
        isLoadingNextPage = false
        errorMessage = nil
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
            species = []
            totalCount = 0
            errorMessage = nil
            isLoading = false
            isLoadingNextPage = false
        case .page(let page, let append):
            species = append ? species + page.items : page.items
            totalCount = page.totalCount
            errorMessage = nil
            isLoading = false
            isLoadingNextPage = false
        case .failure(let message, let append):
            if !append {
                species = []
                totalCount = 0
            }
            errorMessage = message
            isLoading = false
            isLoadingNextPage = false
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
