//
//  RequestHelper.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 10/22/24.
//

import Foundation


protocol RequestConfigurable {
    var headers: [String: String] { get }
    var body: Data? { get }

    func createURLRequest(for endpoint: TripRouter, method: HTTPMethods) -> URLRequest

    func withAdditionalHeaders(_ additionalHeaders: [String: String]) -> RequestConfigurable
}

extension RequestConfigurable {

    func withAdditionalHeaders(_ additionalHeaders: [String: String]) -> RequestConfigurable {
        var modifiedHeaders = headers
        additionalHeaders.forEach { modifiedHeaders[$0] = $1 }
        return CustomRequestConfigurable(headers: modifiedHeaders, body: body)
    }

    func createURLRequest(for endpoint: TripRouter, method: HTTPMethods) -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = method.rawValue
        
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
}

struct CustomRequestConfigurable: RequestConfigurable {
    var headers: [String: String]
    var body: Data?

    init(headers: [String: String], body: Data? = nil) {
        self.headers = headers
        self.body = body
    }
}
