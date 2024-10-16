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
    @Dependency(\.continuousClock) var clock
    @Dependency(\.storiesService) var storiesService
    
    private let storyDuration = 3.0 // seconds
    private let storyPlaybackTimerId = "storyPlaybackTimerId"
    
    @ObservableState
    struct State: Equatable {
        var isLoading = false
        var stories: [Story] = []
        var activeStory: Story?
        var progressState: [Story: Double] = [:]
        var isAutoPlaying = true
    }
    
    enum Action {
        case onAppear
        case loadStories
        case storiesLoaded([Story])
        case timerTick
        case nextStory
        case previousStory
        case startAutoPlay
        case stopAutoPlay
        case onScreenTap
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .send(.loadStories)
            case .loadStories:
                return .run { send in
                    do {
                        let stories = try await storiesService.getStories()
                        await send(.storiesLoaded(stories))
                    } catch {
                        print(error)
                    }
                }
            case .storiesLoaded(let stories):
                state.isLoading = false
                state.stories = stories
                state.progressState = Dictionary(uniqueKeysWithValues: stories.map { ($0, 0.0) })
                state.activeStory = stories.first
                return .send(.startAutoPlay)
            case .timerTick:
                guard let activeStory = state.activeStory else { return .none }
                let activeStoryProgress = state.progressState[activeStory] ?? 0
                
                state.progressState[activeStory] = activeStoryProgress + 1.0/(storyDuration*100)
                
                let newActiveStoryProgress = state.progressState[activeStory] ?? 0
                print(newActiveStoryProgress)
                
                if newActiveStoryProgress >= 1.0 {
                    state.progressState[activeStory] = 1.0
                    return .send(.nextStory)
                }
                
                return .none
            case .nextStory:
                guard let activeStory = state.activeStory else { return .none }
                let currentIndex = state.stories.firstIndex(where: { $0 == activeStory }) ?? 0
                guard currentIndex < (state.stories.count - 1) else {
                    return .none
                }
                state.progressState[activeStory] = 1.0
                state.activeStory = state.stories[currentIndex + 1]
                return .none
            case .previousStory:
                guard let activeStory = state.activeStory else { return .none }
                let currentIndex = state.stories.firstIndex(where: { $0 == activeStory }) ?? 0
                guard currentIndex > 0 else {
                    return .none
                }
                state.progressState[activeStory] = 0
                
                let previousStory = state.stories[currentIndex - 1]
                state.progressState[previousStory] = 0
                state.activeStory = previousStory
                
                return .none
            case .startAutoPlay:
                state.isAutoPlaying = true
                return .run(operation: { send in
                    for await _ in self.clock.timer(interval: .milliseconds(10)) {
                      await send(.timerTick)
                    }
                })
                .cancellable(id: storyPlaybackTimerId)
            case .stopAutoPlay:
                state.isAutoPlaying = false
                return .cancel(id: storyPlaybackTimerId)
            case .onScreenTap:
                return state.isAutoPlaying ? .send(.stopAutoPlay) : .send(.startAutoPlay)
            }
        }
    }
}

struct StoriesScreen: View {
    @Bindable var store:  StoreOf<StoriesFeature>
    @Environment(\.presentationMode) var presentationMode
    
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
                    ForEach(store.stories, id: \.id) { story in
                        let currentStoryProgress = store.progressState[story] ?? 0
                        StoryProgressBarView(progress: currentStoryProgress)
                    }
                }
                .padding(.horizontal, 10)
            
            if let activeStory = store.activeStory {
                Image(activeStory.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width < 0 {
                                    store.send(.nextStory)
                                } else if value.translation.width > 0 {
                                    store.send(.previousStory)
                                }
                            }
                    )
                    .onTapGesture {
                        store.send(.onScreenTap)
                    }
            }
        }
        .onAppear(perform: { store.send(.onAppear) })
        .opacity(store.isLoading ? 0 : 1)
        .overlay {
            if store.isLoading {
                ProgressView()
            }
        }
    }
}
