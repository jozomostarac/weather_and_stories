//
//  WeatherScreen.swift
//  WeatherAndStories
//
//  Created by Jozo Mostarac on 10.10.2024..
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct WeatherFeature {
    
    @Dependency(\.locationService) var locationService
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        var locationAuthorizationStatus: LocationAuthorizationStatus = .unknown
        var location: Location?
    }
    
    enum Action {
        case destination(PresentationAction<Destination.Action>)
        case checkStoriesButtonTapped
        case requestLocation
        case locationUpdated(Location)
        case authorizationStatusUpdated(LocationAuthorizationStatus)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .checkStoriesButtonTapped:
                state.destination = .stories(StoriesFeature.State())
                return .none
            case .destination:
                return .none
            case .requestLocation:
                locationService.requestPermission()
                return .merge(
                    Effect.publisher({
                        locationService.authorizationStatusUpdates
                            .map(Action.authorizationStatusUpdated)
                            .receive(on: DispatchQueue.main)
                    }),
                    Effect.publisher({
                        locationService.locationUpdates
                            .map(Action.locationUpdated)
                            .receive(on: DispatchQueue.main)
                    })
                )
            case .locationUpdated(let location):
                state.location = location
                return .none
            case .authorizationStatusUpdated(let status):
                state.locationAuthorizationStatus = status
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
                Spacer()
                Button {
                    store.send(.checkStoriesButtonTapped)
                } label: {
                    Text("Check new stories")
                }
            }
        }
        .onAppear(perform: { store.send(.requestLocation) })
        .sheet(
            item: $store.scope(state: \.destination?.stories, action: \.destination.stories)
        ) { storiesStore in
            StoriesScreen(store: storiesStore)
                .presentationCompactAdaptation(.fullScreenCover)
        }
    }
}
