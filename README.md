# Weather and Stories

## SwiftUI and The Composable Architecture Example App

### Features

#### Weather Screen
- Displays the current temperature for the user's location
    - Requests the user's location permission
    - Fetches the user's location upon permission approval
    - Retrieves weather information for the user's location from a remote source
    - Shows weather information to the user
    - Provides an option to navigate to the **Stories** screen

#### Stories Screen
- Displays a series of images that auto-progress and can be manually swiped
    - Loads images from a mocked data source
    - Shows images as a series of "Stories" which auto-progress
    - Allows the auto-progress feature to be paused and resumed by tapping an image
    - Enables manual advancement of the stories by swiping on an image

### Tech Stack
The app uses **SwiftUI** and **The Composable Architecture**. No other third-party dependencies are used.  
It demonstrates the use of TCA for:
- Defining features
- Implementing navigation
- Using dependency injection
- Providing tests
