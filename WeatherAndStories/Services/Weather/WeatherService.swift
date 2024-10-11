//
//  WeatherService.swift
//  WeatherAndStories
//
//  Created by Jozo Mostarac on 11.10.2024..
//

import Foundation
import ComposableArchitecture

protocol WeatherService {
    func getWeather(forLocation location: Location) async throws -> Weather
}

fileprivate let apiHost = "https://api.open-meteo.com"

fileprivate enum Endpoint: String {
    case forecast = "/v1/forecast"
}

struct WeatherServiceImpl: WeatherService {
    
    let urlSession = URLSession.shared
    
    func getWeather(forLocation location: Location) async throws -> Weather {
        var components = URLComponents(string: apiHost + Endpoint.forecast.rawValue)
         
         components?.queryItems = [
             URLQueryItem(name: "latitude", value: "\(location.lat)"),
             URLQueryItem(name: "longitude", value: "\(location.long)"),
             URLQueryItem(name: "current", value: "temperature_2m,wind_speed_10m")
         ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await urlSession.data(from: url)
        
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        return try decoder.decode(Weather.self, from: data)
    }
}

// MARK: - TCA Dependencies

private enum WeatherServiceKey: DependencyKey {
    static let liveValue: WeatherService = WeatherServiceImpl()
}

extension DependencyValues {
    var weatherService: WeatherService {
        get { self[WeatherServiceKey.self] }
        set { self[WeatherServiceKey.self] = newValue }
    }
}
