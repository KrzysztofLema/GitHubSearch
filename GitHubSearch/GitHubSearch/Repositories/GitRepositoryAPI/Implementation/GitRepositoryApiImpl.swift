//
//  GitRepositoryApiImpl.swift
//  GitHubSearch
//
//  Created by Krzysztof Lema on 11/03/2021.
//

import Foundation
import Combine

class GitRepositoryApiImpl: GitRepositoryAPI {
    
    let urlSession: URLSession
    
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    func getRepositorySearchResult(
        for text: String,
        sortedBy sorting: Sorting? = .numberOfStars
    ) -> AnyPublisher<GitResponse, GitRepositoryAPIError> {

            var components = URLComponents()
            components.scheme = "https"
            components.host = "api.github.com"
            components.path = "/search/repositories"
            components.queryItems = [
                URLQueryItem(name: "q", value: text),
                URLQueryItem(name: "sort", value: sorting?.rawValue)
            ]
            
        return urlSession.dataTaskPublisher(for: components.url!)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                    throw GitRepositoryAPIError.badHTTPResponse
               }
               return data
            }
            .decode(type: GitResponse.self, decoder: JSONDecoder())
            .mapError { error -> GitRepositoryAPIError in
                if let error = error as? GitRepositoryAPIError {
                    return error
                } else {
                    return GitRepositoryAPIError.decoding
                }
            }
            .eraseToAnyPublisher()
    }
}
