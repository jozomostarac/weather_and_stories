//
//  WeatherScreen.swift
//  WeatherAndStories
//
//  Created by Jozo Mostarac on 10.10.2024..
//

import SwiftUI
import Combine
import ComposableArchitecture

@Reducer
struct WeatherFeature {
    
    @Dependency(\.locationService) var locationService
    @Dependency(\.weatherService) var weatherService
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        var isLoading = false
        var locationAuthorizationStatus: LocationAuthorizationStatus = .unknown
        var location: Location?
        var weather: Weather?
    }
    
    enum Action {
        case onAppear
        case destination(PresentationAction<Destination.Action>)
        case checkStoriesButtonTapped
        case requestLocation
        case locationUpdated(Location)
        case authorizationStatusUpdated(LocationAuthorizationStatus)
        case getWeather
        case weatherUpdated(Weather)
        case error(Error)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .send(.requestLocation)
            case .checkStoriesButtonTapped:
                state.destination = .stories(StoriesFeature.State())
                return .none
            case .destination:
                return .none
            case .requestLocation:
                locationService.requestPermission()
                locationService.requestLocation()
                return .merge(
                    Effect.publisher({
                        locationService.authorizationStatusUpdates
                            .receive(on: DispatchQueue.main)
                            .map(Action.authorizationStatusUpdated)
                            .catch { Just(Action.error($0)) }
                            
                    }),
                    Effect.publisher({
                        locationService.locationUpdates
                            .receive(on: DispatchQueue.main)
                            .map(Action.locationUpdated)
                            .catch { Just(Action.error($0)) }
                    })
                )
            case .locationUpdated(let location):
                state.location = location
                return .send(.getWeather)
            case .authorizationStatusUpdated(let status):
                state.locationAuthorizationStatus = status
                if status == .approved {
                    locationService.requestLocation()
                }
                return .none
            case .getWeather:
                if let location = state.location {
                    return Effect.run { send in
                        let weather = try await weatherService.getWeather(forLocation: location)
                        await send(.weatherUpdated(weather))
                    } catch: { error, send in
                        await  send(.error(error))
                    }
                }
                return .none
            case .weatherUpdated(let weather):
                state.isLoading = false
                state.weather = weather
                return .none
            case .error(let error):
                state.isLoading = false
                print(error)
                // show error
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension WeatherFeature {
    @Reducer(state: .equatable)
    enum Destination {
        case stories(StoriesFeature)
    }
}

struct WeatherScreen: View {
    @Bindable var store: StoreOf<WeatherFeature>
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Weather screen")
                if store.locationAuthorizationStatus == .unknown {
                    Text("Authorization status - UNKNOWN")
                } else {
                    Text("Authorization status - APPROVED OR DENIED")
                }
                
                if let location = store.location {
                    Text("---")
                    Text(location.cityName ?? "Unknown city")
                    Text("---")
                }
                
                if let weather = store.weather {
                    Text("Weather")
                    Text("\(weather.current.time)")
                    Text("\(weather.current.temperature)")
                    Text("\(weather.current.windSpeed)")
                    Text("---")
                }
                Spacer()
                Button {
                    store.send(.checkStoriesButtonTapped)
                } label: {
                    Text("Check new stories")
                }
            }
            .opacity(store.isLoading ? 0 : 1)
            .overlay {
                if store.isLoading {
                    ProgressView()
                }
            }
        }
        .onAppear(perform: { store.send(.onAppear) })
        .sheet(
            item: $store.scope(state: \.destination?.stories, action: \.destination.stories)
        ) { storiesStore in
            StoriesScreen(store: storiesStore)
                .presentationCompactAdaptation(.fullScreenCover)
        }
    }
}
