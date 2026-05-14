//
//  NetworkService.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import Combine
import Foundation

protocol NetworkServiceType {
    func request<Response: Decodable>(_ request: URLRequest) -> AnyPublisher<Response, Error>
}

final class NetworkService: NetworkServiceType {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func request<Response: Decodable>(_ request: URLRequest) -> AnyPublisher<Response, Error> {
        session.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                guard 200..<300 ~= response.statusCode else {
                    throw NetworkError.unacceptableStatusCode(response.statusCode)
                }
                return output.data
            }
            .decode(type: Response.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
}

enum NetworkError: LocalizedError, Equatable {
    case invalidResponse
    case unacceptableStatusCode(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server."
        case .unacceptableStatusCode(let statusCode):
            return "Server returned status code \(statusCode)."
        }
    }
}
