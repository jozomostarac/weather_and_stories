//
//  WeatherAndStoriesApp.swift
//  WeatherAndStories
//
//  Created by Jozo Mostarac on 10.10.2024..
//

import SwiftUI
import ComposableArchitecture

@main
struct WeatherAndStoriesApp: App {
    var body: some Scene {
        WindowGroup {
            WeatherScreen(
                store: Store(
                    initialState: WeatherFeature.State()
                ) {
                    WeatherFeature()
                }
            )
        }
    }
}
