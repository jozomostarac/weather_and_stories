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
        var isLoading = false
        var stories: [Story] = []
        var currentStoryIndex = 0
    }
    
    enum Action {
        case onAppear
        case loadStories
        case storiesLoaded([Story])
        case nextStory
        case previousStory
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .send(.loadStories)
            case .loadStories:
                return .run { send in
                    try? await Task.sleep(for: .seconds(1))
                    await send(.storiesLoaded(Story.mockedList))
                }
            case .storiesLoaded(let stories):
                state.isLoading = false
                state.stories = stories
                state.currentStoryIndex = 0
            case .nextStory:
                guard state.currentStoryIndex < (state.stories.count - 1) else {
                    state.currentStoryIndex = state.stories.count - 1
                    return .none
                }
                state.currentStoryIndex += 1
                return .none
            case .previousStory:
                guard state.currentStoryIndex > 0 else {
                    state.currentStoryIndex = 0
                    return .none
                }
                state.currentStoryIndex -= 1
                return .none
            }
            return .none
        }
    }
}

struct StoriesScreen: View {
    @Bindable var store:  StoreOf<StoriesFeature>
    @Environment(\.presentationMode) var presentationMode
    
    var currentStory: Story {
        store.stories[store.currentStoryIndex]
    }
    
    var body: some View {
        VStack(spacing: 10) {
                HStack {
                    Spacer()
                    Image(systemName: "xmark")
                        .frame(width: 30, height: 30)
                        .onTapGesture {
                            presentationMode.wrappedValue.dismiss()
                        }
                }
                HStack {
                    ForEach(1..<6) { _ in
                        StoryProgressBar()
                    }
                }
                .padding(.horizontal, 10)
            
            Image(currentStory.image)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width)
                .swipeActions {
                    <#code#>
                }
        }
    }
}

struct StoryProgressBar: View {
    @State private var progress = 0.0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.25)) // Background Rectangle
            .frame(height: 10)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue) // Foreground Rectangle
                    .frame(width: CGFloat(progress), height: 10)
                    .animation(.linear(duration: 1), value: progress) // Animate width change
            }
            .onReceive(timer) { _ in
                if progress < 100 {
                    withAnimation {
                        progress += 20 // Increment progress
                    }
                }
            }
            .frame(maxWidth: .infinity) // Ensure it stretches to the parent width
    }
}
