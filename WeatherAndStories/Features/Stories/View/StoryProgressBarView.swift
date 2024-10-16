//
//  StoryProgressBarView.swift
//  WeatherAndStories
//
//  Created by Jozo Mostarac on 16.10.2024..
//

import SwiftUI

struct StoryProgressBarView: View {
    let progress: Double
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.gray.opacity(0.25))
            .frame(height: 4)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
    }
}
