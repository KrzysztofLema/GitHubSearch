//
//  GitRepositoryAPITests.swift
//  GitHubSearchTests
//
//  Created by Krzysztof Lema on 12/03/2021.
//

import Foundation
import XCTest
import Combine
@testable import GitHubSearch

class GitRepositoryAPITests: XCTestCase {
    
    var sut: GitRepositoryApiImpl!
    var session: URLSession!
    var subscriptions = Set<AnyCancellable>()
    
    override func setUp() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        sut = GitRepositoryApiImpl(urlSession: session)
    }
    
    override func tearDown() {
        sut = nil
        session = nil
    }
    
    func test_whenTheStatusCodeIs200_AfterSendRequest_ShouldReceiveData() {
        // given
        let expectation = XCTestExpectation(description: "resume() triggered")
        let expectedValue =  GitResponse(items: [
            GitRepository(
                id: 0, name: "Krzysztof", url: URL(string: "www.google.pl"),
                owner: Owner(avatar: URL(string: "")))
        ])
        MockURLProtocol.testData = try? JSONEncoder().encode(GitResponse(items: [
            GitRepository(
                id: 0, name: "Krzysztof", url: URL(string: "www.google.pl"),
                owner: Owner(avatar: URL(string: "")))
        ]))
        MockURLProtocol.statusCode = 200
        var receivedValue: GitResponse?
        //when
        sut.getRepositorySearchResult(for: "asd")
            .sink { _ in } receiveValue: { received in
                receivedValue = received
                expectation.fulfill()
            }.store(in: &subscriptions)

        wait(for: [expectation], timeout: 1.0)
        //then
        XCTAssertEqual(expectedValue, receivedValue)
    }

    func test_whenTheStatusCodeIs400_AfterSendRequest_ShouldNotReceiveData() {
        //given
        let expectation = XCTestExpectation(description: "resume() triggered")
        MockURLProtocol.statusCode = 400
        //when
        sut.getRepositorySearchResult(for: "asd")
            .sink { completion in
                switch completion {
                case .finished:
                    XCTFail("Expected to succeed but received error")
                case .failure(let error):
                    do {
                        let error = try XCTUnwrap(error as! GitRepositoryAPIError)
                        XCTAssertEqual(error, .badHTTPResponse)
                    } catch {
                        XCTFail("")
                    }
                }
                expectation.fulfill()
            } receiveValue: { _ in }
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_whenTheStatusCodeIs200_AfterSenSerializedWrongRequest_ApiClientErrorIsDecoding() throws {
        let expectation = XCTestExpectation(description: "expected decoding error")
        MockURLProtocol.testData = Data()

        MockURLProtocol.statusCode = 200

        sut.getRepositorySearchResult(for: "asd")
            .sink { completion in
                switch completion {
                case .failure(let error):
                    do {
                        let error = try XCTUnwrap(error as GitRepositoryAPIError)
                        XCTAssertEqual(error, .decoding)
                        expectation.fulfill()
                    } catch {
                        XCTFail("")
                    }
                case .finished:
                    XCTFail("")
                }
            } receiveValue: { _ in }
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1.0)
    }

}




