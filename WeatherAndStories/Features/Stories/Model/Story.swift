//
//  Story.swift
//  WeatherAndStories
//
//  Created by Jozo Mostarac on 14.10.2024..
//

import Foundation

struct Story: Equatable {
    let id: String
    let image: String
}

extension Story {
    static var mockedList: [Story] {
        [
            Story(id: "1", image: "stories_1"),
            Story(id: "2", image: "stories_2"),
            Story(id: "3", image: "stories_3"),
            Story(id: "4", image: "stories_4"),
            Story(id: "5", image: "stories_5")
        ]
    }
}
