//
//  FetchService.swift
//  Loader
//
//  Created by samara on 14.03.2025.
//

import Foundation

// MARK: - Class
public class FetchService {
	public enum FetchServiceError: Error, LocalizedError {
		case invalidURL
		case networkError(Error)
		case noData
		case parsingError(Error)
		
		public var errorDescription: String? {
			switch self {
			case .invalidURL:
				return "The URL is invalid."
			case .networkError(let error):
				return "Network error: \(error.localizedDescription)"
			case .noData:
				return "No data received."
			case .parsingError(let error):
				return "Failed to parse data: \(error.localizedDescription)"
			}
		}
	}
	
	public init() {}
}

// MARK: - Class extension: fetch
extension FetchService {
	public func fetch<T: Decodable>(from urlString: String, completion: @escaping (Result<T, Error>) -> Void) {
		guard let url = URL(string: urlString) else {
			completion(.failure(FetchServiceError.invalidURL))
			return
		}
		
		fetch(from: url, completion: completion)
	}
	
	public func fetch<T: Decodable>(from url: URL, completion: @escaping (Result<T, Error>) -> Void) {
		DispatchQueue.global(qos: .userInitiated).async {
			let task = URLSession.shared.dataTask(with: url) { data, response, error in
				if let error = error {
					completion(.failure(FetchServiceError.networkError(error)))
					return
				}
				
				guard let data = data else {
					completion(.failure(FetchServiceError.noData))
					return
				}
				
				do {
					let decoder = JSONDecoder()
					let decodedData = try decoder.decode(T.self, from: data)
					completion(.success(decodedData))
				} catch {
					completion(.failure(FetchServiceError.parsingError(error)))
				}
			}
			
			task.resume()
		}
	}
}
