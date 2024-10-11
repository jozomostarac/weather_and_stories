//
//  Date+Extensions.swift
//  WeatherAndStories
//
//  Created by Jozo Mostarac on 11.10.2024..
//

import Foundation

extension Date {
    func toFormattedDateTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_GB")
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        return dateFormatter.string(from: self)
    }
}
