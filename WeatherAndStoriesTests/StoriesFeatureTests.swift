//
//  StoriesFeatureTests.swift
//  StoriesFeatureTests
//
//  Created by Jozo Mostarac on 10.10.2024..
//

import XCTest
import ComposableArchitecture
@testable import WeatherAndStories

final class WeatherAndStoriesTests: XCTestCase {
    var store: TestStore<StoriesFeature.State, StoriesFeature.Action>!

    @MainActor
    override func setUp() {
        store = TestStore(
            initialState: StoriesFeature.State(),
            reducer: { StoriesFeature() }
        ) {
            $0.continuousClock = TestClock()
        }
        
        store.exhaustivity = .off
    }

    override func tearDown() {
        store = nil
    }

    func testStoriesLoading() async {
        await store.send(.onAppear) {
            $0.isLoading = true
            $0.stories = []
            $0.activeStory = nil
            $0.progressState = [:]
        }
        
        let mockedStories = Story.mockedList
        
        await store.receive(\.storiesLoaded) {
            $0.isLoading = false
            $0.stories = mockedStories
            $0.activeStory = mockedStories.first
            $0.progressState = [
                mockedStories[0]: 0.0, 
                mockedStories[1]: 0.0,
                mockedStories[2]: 0.0,
                mockedStories[3]: 0.0,
                mockedStories[4]: 0.0
            ]
        }
    }

    func testNextStory() async {
        await store.send(\.onAppear)
        await store.receive(\.storiesLoaded)
        
        await store.send(\.nextStory) {
            $0.progressState[$0.stories.first!] = 1.0
        }
    }
    
    func testPreviousStory() async {
        await store.send(\.onAppear)
        await store.receive(\.storiesLoaded)
        
        await store.send(\.nextStory)
        await store.send(\.nextStory)
        
        await store.send(.previousStory) {
            $0.progressState[$0.stories[0]] = 1.0
            $0.progressState[$0.stories[1]] = 0
            $0.progressState[$0.stories[2]] = 0
        }
    }
    
    @MainActor
    func testOnScreenTap_ToggleAutoPlay() async {
        let clock = TestClock()
        let store = TestStore(
            initialState: StoriesFeature.State(),
            reducer: { StoriesFeature() }
        ) {
            $0.continuousClock = clock
        }
        store.exhaustivity = .off
        
        await store.send(\.onAppear)
        await store.receive(\.storiesLoaded)
        
        await clock.advance(by: .seconds(1))
        
        // Pause auto play
        await store.send(.onScreenTap) {
            $0.isAutoPlaying = false
        }
        
        // Advance time
        await clock.advance(by: .seconds(10))
        
        // Restart auto play and check if the same story is still active
        await store.send(.onScreenTap) {
            $0.isAutoPlaying = true
            $0.activeStory = $0.stories[0]
        }
    }

    @MainActor
    func testAutoPlay() async {
        let clock = TestClock()
        let store = TestStore(
            initialState: StoriesFeature.State(),
            reducer: { StoriesFeature() }
        ) {
            $0.continuousClock = clock
        }
        store.exhaustivity = .off
        
        await store.send(\.onAppear)
        await store.receive(\.startAutoPlay)

        await clock.advance(by: .seconds(4))
            
        await store.receive(\.nextStory) {
            $0.activeStory = $0.stories[1]
        }
    }
}
