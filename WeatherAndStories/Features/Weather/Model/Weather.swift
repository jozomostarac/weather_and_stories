//
//  Weather.swift
//  WeatherAndStories
//
//  Created by Jozo Mostarac on 11.10.2024..
//

import Foundation

struct Weather: Codable, Equatable {
    let units: Units
    let current: Current
    
    enum CodingKeys: String, CodingKey {
        case units = "current_units"
        case current
    }
}

extension Weather {
    struct Units: Codable, Equatable {
        let temperature2m: String
        let windSpeed10m: String
        
        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case windSpeed10m = "wind_speed_10m"
        }
    }
    
    struct Current: Codable, Equatable {
        let time: Date
        let temperature: Double
        let windSpeed: Double
        
        enum CodingKeys: String, CodingKey {
            case time
            case temperature = "temperature_2m"
            case windSpeed = "wind_speed_10m"
        }
    }
}
