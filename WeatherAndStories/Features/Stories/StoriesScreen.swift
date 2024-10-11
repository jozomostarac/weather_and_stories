//
//  StoriesScreen.swift
//  WeatherAndStories
//
//  Created by Jozo Mostarac on 10.10.2024..
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct StoriesFeature {
    @ObservableState
    struct State: Equatable {
        
    }
    
    enum Action {
        
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            return .none
        }
    }
}

struct StoriesScreen: View {
    @Bindable var store:  StoreOf<StoriesFeature>
    
    var body: some View {
        Text("Stories screen")
    }
}
