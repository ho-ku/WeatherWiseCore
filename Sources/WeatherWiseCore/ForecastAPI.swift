//
//  ForecastAPI.swift
//  WeatherWiseCore
//
//  Created by Денис Андриевский on 31.07.2023.
//

import Foundation

extension String: Error {}

public protocol URLSessionRepresentable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}
extension URLSession: URLSessionRepresentable {}

public protocol Decoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}
extension JSONDecoder: Decoder {}

public protocol AnyForecastAPI {
    
    /// Method that returns a list of forecastst for specified coordinate
    func forecast(coordinate: (lat: String, lon: String)) async throws -> [Forecast]
}

final class ForecastAPI: AnyForecastAPI {
    
    enum Path: String {
        case forecast = "/forecast"
    }
    
    // MARK: - Properties
    
    private let apiKey: String
    private let urlSession: URLSessionRepresentable
    private let decoder: Decoder
    
    // MARK: - Init
    
    init(apiKey: String, urlSession: URLSessionRepresentable, decoder: Decoder) {
        self.apiKey = apiKey
        self.urlSession = urlSession
        self.decoder = decoder
    }
    
    // MARK: - Methods
    
    func forecast(coordinate: (lat: String, lon: String)) async throws -> [Forecast] {
        guard var urlComps = URLComponents(string: APIConfig.baseURL + Path.forecast.rawValue) else { throw "Unable to construct URL components" }
        urlComps.queryItems = [
            .init(name: "lat", value: coordinate.lat),
            .init(name: "lon", value: coordinate.lon),
            .init(name: "appid", value: apiKey),
            .init(name: "units", value: "metric")
        ]
        guard let url = urlComps.url else { throw "Unable to construct URL" }
        
        let (data, _) = try await urlSession.data(from: url)
        let decoded = try decoder.decode(Forecast.ForecastDecodable.self, from: data)
        return decoded.list.map { .init($0) }
    }
    
}

// MARK: - Builder

public final class ForecastBuilder {
    
    private let urlSession: URLSessionRepresentable
    private let decoder: Decoder
    private var apiKey: String = ""
    
    public init(urlSession: URLSessionRepresentable, decoder: Decoder) {
        self.urlSession = urlSession
        self.decoder = decoder
    }
    
    public func withAPIKey(_ key: String) -> Self {
        apiKey = key
        return self
    }
    
    public func build() -> AnyForecastAPI {
        ForecastAPI(apiKey: apiKey, urlSession: urlSession, decoder: decoder)
    }
    
}
