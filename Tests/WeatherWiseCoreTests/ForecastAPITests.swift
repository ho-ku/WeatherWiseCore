//
//  ForecastAPITests.swift
//  WeatherWiseCoreTests
//
//  Created by Денис Андриевский on 31.07.2023.
//

import XCTest
@testable import WeatherWiseCore

final class ForecastAPITests: XCTestCase {
    
    func testForecastSuccess() async throws {
        // GIVEN
        let forecast = Forecast.ForecastDecodable(list: [.init(date: .init(), main: .init(temp: .zero), weather: [])])
        let urlSession = URLSessionRepresentableMock(expectedResult: .success(.init()))
        let decoder = DecoderMock(expectedResult: .success(forecast))
        let sut = makeSUT(session: urlSession, decoder: decoder)
        // WHEN
        let receivedForecast = try await sut.forecast(coordinate: ("", ""))
        // THEN
        XCTAssertEqual(receivedForecast.count, forecast.list.count)
    }
    
    func testForecastFailure() async {
        // GIVEN
        let forecast = Forecast.ForecastDecodable(list: [.init(date: .init(), main: .init(temp: .zero), weather: [])])
        let urlSession = URLSessionRepresentableMock(expectedResult: .failure(""))
        let decoder = DecoderMock(expectedResult: .success(forecast))
        let sut = makeSUT(session: urlSession, decoder: decoder)
        // WHEN
        do {
            _ = try await sut.forecast(coordinate: ("", ""))
            // THEN
            XCTFail("Expect to get error")
        } catch {}
    }
    
    func testForecastDecoderFailure() async {
        // GIVEN
        let urlSession = URLSessionRepresentableMock(expectedResult: .success(.init()))
        let decoder = DecoderMock<Forecast.ForecastDecodable>(expectedResult: .failure(""))
        let sut = makeSUT(session: urlSession, decoder: decoder)
        // WHEN
        do {
            _ = try await sut.forecast(coordinate: ("", ""))
            // THEN
            XCTFail("Expect to get error")
        } catch {}
    }
    
    func testBuilder() async throws {
        // GIVEN
        let forecast = Forecast.ForecastDecodable(list: [.init(date: .init(), main: .init(temp: .zero), weather: [])])
        let urlSession = URLSessionRepresentableMock(expectedResult: .success(.init()))
        let decoder = DecoderMock<Forecast.ForecastDecodable>(expectedResult: .success(forecast))
        let sut = ForecastBuilder(
            urlSession: urlSession,
            decoder: decoder
        )
            .withAPIKey("")
            .build()
        // WHEN
        let receivedForecast = try await sut.forecast(coordinate: ("", ""))
        // THEN
        XCTAssertEqual(receivedForecast.count, forecast.list.count)
    }

    // MARK: - Private Helpers
    
    private func makeSUT(session: URLSessionRepresentable, decoder: Decoder) -> AnyForecastAPI {
        ForecastAPI(apiKey: "", urlSession: session, decoder: decoder)
    }

}

// MARK: - Mocks

private extension ForecastAPITests {
    final class URLSessionRepresentableMock: URLSessionRepresentable {
        
        private let expectedResult: Result<Data, Error>
        
        init(expectedResult: Result<Data, Error>) {
            self.expectedResult = expectedResult
        }
        
        func data(from url: URL) async throws -> (Data, URLResponse) {
            switch expectedResult {
            case .success(let success):
                return (success, .init())
            case .failure(let failure):
                throw failure
            }
        }
    }
    
    final class DecoderMock<T: Decodable>: Decoder {
        
        private let expectedResult: Result<T, Error>
        
        init(expectedResult: Result<T, Error>) {
            self.expectedResult = expectedResult
        }
        
        func decode<T>(_ type: T.Type, from data: Data) throws -> T {
            switch expectedResult {
            case .success(let success):
                return success as! T
            case .failure(let failure):
                throw failure
            }
        }
    }
}
