//
//  HomeViewModel.swift
//  GitHubSearch
//
//  Created by Krzysztof Lema on 10/03/2021.
//

import Foundation
import Combine
class HomeViewModel {
    
    @Published var searchInput: String = ""
    @Published private(set) var gitRepositoryResults: [GitRepository] = []
    @Published var homeViewState: HomeViewState = .defaultState
    
    let selectedRepository = PassthroughSubject<GitRepository, Never>()
    let apiError = PassthroughSubject<GitRepositoryAPIError, Never>()
    
    init(gitRepositoryApi: GitRepositoryAPI) {
        self.gitRepositoryApi = gitRepositoryApi
        bind()
    }
    
    func bind() {
        $searchInput
            .debounce(for: .milliseconds(800), scheduler: RunLoop.main)
            .filter { !$0.isEmpty }
            .sink { [weak self] searchValue in
            guard let self = self else { return }
            self.homeViewState = .isLoadingData
            self.searchForGitRepositories(with: searchValue)
        }.store(in: &subscriptions)
        
        $searchInput
            .filter { $0.isEmpty }
            .sink { _ in
                self.homeViewState = .defaultState
                self.gitRepositoryResults = []
            }
            .store(in: &subscriptions)
    }
    
    private let gitRepositoryApi: GitRepositoryAPI
    private var subscriptions = Set<AnyCancellable>()
}

private extension HomeViewModel {
    func searchForGitRepositories(with searchInput: String) {
        gitRepositoryApi
            .getRepositorySearchResult(for: searchInput, sortedBy: .numberOfStars)
            .sink { [weak self] error in
                guard let self = self else { return }
                if case .failure(let error) = error {
                    let error = error as? GitRepositoryAPIError
                    self.apiError.send(error!)
                }
            } receiveValue: { [weak self] searchResult in
                guard let self = self, let searchResult = searchResult.items else { return }
                self.homeViewState = .loadedData
                self.gitRepositoryResults = searchResult
            }.store(in: &subscriptions)
    }
}

enum HomeViewState {
    case isLoadingData
    case loadedData
    case defaultState
}
