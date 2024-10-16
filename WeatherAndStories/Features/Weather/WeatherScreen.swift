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
        @Presents var errorAlert: AlertState<Action.Alert>?
        @Presents var destination: Destination.State?
        var isLoading = false
        var locationAuthorizationStatus: LocationAuthorizationStatus = .unknown
        var location: Location?
        var weather: Weather?
    }
    
    enum Action {
        case errorAlert(PresentationAction<Alert>)
        case destination(PresentationAction<Destination.Action>)
        case onAppear
        case checkStoriesButtonTapped
        case requestLocation
        case locationUpdated(Location)
        case authorizationStatusUpdated(LocationAuthorizationStatus)
        case getWeather
        case weatherUpdated(Weather)
        case error(Error)
        
        @CasePathable
        enum Alert {
          case okButtonTapped
        }
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
                state.errorAlert = AlertState {
                    TextState(error.localizedDescription)
                } actions: {
                  ButtonState(action: .okButtonTapped) {
                    TextState("OK")
                  }
                }
                return .none
            case .errorAlert(.presented(.okButtonTapped)):
                state.errorAlert = nil
                return .none
            case .errorAlert(.dismiss):
                state.errorAlert = nil
                return .none
            }
        }
        .ifLet(\.$errorAlert, action: \.errorAlert)
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
            ZStack {
                Color.blue.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)

                    VStack {
                        Text("Current weather")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.vertical, 20)
                        
                        VStack(spacing: 10) {
                            if let location = store.location {
                                Text(location.cityName ?? "Unknown city")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding(.bottom, 20)
                            }
                            
                            if let weather = store.weather {
                                Text(weather.current.time.toFormattedDateTime())
                                
                                HStack(spacing: 5) {
                                    Text(String(format: "Temperature: %.1f", weather.current.temperature))
                                    Text(weather.units.temperature)
                                }
                                
                                HStack(spacing: 5) {
                                    Text(String(format: "Wind Speed: %.1f", weather.current.windSpeed))
                                    Text(weather.units.windSpeed)
                                }
                            } else {
                                Text("No data available")
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.top, 40)
                        
                        Spacer()
                        
                        Button {
                            store.send(.checkStoriesButtonTapped)
                        } label: {
                            Text("Check new weather stories")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxHeight: .infinity)
                .opacity(store.isLoading ? 0 : 1)
                .overlay {
                    if store.isLoading {
                        ProgressView()
                    }
                }
            }
        }
        .onAppear(perform: { store.send(.onAppear) })
        .alert($store.scope(state: \.errorAlert, action: \.errorAlert))
        .sheet(
            item: $store.scope(state: \.destination?.stories, action: \.destination.stories)
        ) { storiesStore in
            StoriesScreen(store: storiesStore)
                .presentationCompactAdaptation(.fullScreenCover)
        }
    }
}
