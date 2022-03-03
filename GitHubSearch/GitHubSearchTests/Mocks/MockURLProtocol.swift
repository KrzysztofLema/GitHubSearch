//
//  MockURLProtocol.swift
//  GitHubSearchTests
//
//  Created by Krzysztof Lema on 02/03/2022.
//

import Foundation

class MockURLProtocol: URLProtocol {
    static var testData: Data?
    static var statusCode: Int?
    static func mockResponse(url: URL, statusCode: Int) -> HTTPURLResponse? {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        self.client?.urlProtocol(
            self,
            didReceive: MockURLProtocol.mockResponse(
                url:request.url!,
                statusCode: MockURLProtocol.statusCode!)!,
            cacheStoragePolicy: .notAllowed
        )
        self.client?.urlProtocol(
            self,
            didLoad: MockURLProtocol.testData ?? Data()
        )

        self.client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

}
