//
//  StoriesService.swift
//  WeatherAndStories
//
//  Created by Jozo Mostarac on 16.10.2024..
//

import Foundation
import ComposableArchitecture

protocol StoriesService {
    func getStories() async throws -> [Story]
}

struct StoriesServiceImpl: StoriesService {
    func getStories() async throws -> [Story] {
        try await Task.sleep(for: .seconds(1))
        return Story.mockedList
    }
}

// MARK: - TCA Dependencies

enum StoriesServiceKey: DependencyKey {
    static let liveValue: StoriesService = StoriesServiceImpl()
}

extension DependencyValues {
    var storiesService: StoriesService {
        get { self[StoriesServiceKey.self] }
        set { self[StoriesServiceKey.self] = newValue }
    }
}


// MARK: - Testing

struct MockStoriesService: StoriesService {
    func getStories() async throws -> [Story] {
        try await Task.sleep(for: .seconds(1))
        return Story.mockedList
    }
}

extension StoriesServiceKey: TestDependencyKey {
    static let testValue: StoriesService = MockStoriesService()
}
