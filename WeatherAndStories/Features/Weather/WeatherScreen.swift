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
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
    }
    
    enum Action {
        case destination(PresentationAction<Destination.Action>)
        case checkStoriesButtonTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .checkStoriesButtonTapped:
                state.destination = .stories(StoriesFeature.State())
                return .none
            case .destination:
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
                Spacer()
                Button {
                    store.send(.checkStoriesButtonTapped)
                } label: {
                    Text("Check new stories")
                }
            }
        }
        .sheet(
            item: $store.scope(state: \.destination?.stories, action: \.destination.stories)
        ) { storiesStore in
            StoriesScreen(store: storiesStore)
                .presentationCompactAdaptation(.fullScreenCover)
        }
    }
}
