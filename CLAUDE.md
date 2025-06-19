# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI-based iOS/macOS application written in Swift. It uses Xcode as the primary development environment.

## Development Commands

### Building
```bash
# Build for debug
xcodebuild -project "CaluFC.xcodeproj" -scheme "CaluFC" -configuration Debug build

# Build for release
xcodebuild -project "CaluFC.xcodeproj" -scheme "CaluFC" -configuration Release build

# Clean build folder
xcodebuild -project "CaluFC.xcodeproj" -scheme "CaluFC" clean
```

### Testing
```bash
# Run unit tests
xcodebuild test -project "CaluFC.xcodeproj" -scheme "CaluFC" -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -project "CaluFC.xcodeproj" -scheme "CaluFC" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"CaluFCUITests"

# Run a specific test
xcodebuild test -project "CaluFC.xcodeproj" -scheme "CaluFC" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"CaluFCTests/TestClassName/testMethodName"
```

### Running the App
```bash
# Open in Xcode
open "CaluFC.xcodeproj"

# Build and run on simulator
xcodebuild -project "CaluFC.xcodeproj" -scheme "CaluFC" -destination 'platform=iOS Simulator,name=iPhone 15' -derivedDataPath build
```

## Architecture

The project follows standard SwiftUI app architecture:

- **Entry Point**: `CaluFC/CaluFCApp.swift` - Contains the @main attribute and app lifecycle
- **Views**: `CaluFC/ContentView.swift` - Main UI views using SwiftUI declarative syntax
- **Resources**: `CaluFC/Assets.xcassets/` - Contains app icons, colors, and other visual assets
- **Tests**: Uses Swift Testing framework for unit tests and XCUITest for UI automation

The app uses SwiftUI's declarative programming model where views are structs conforming to the View protocol, and state is managed through property wrappers like @State, @StateObject, and @ObservedObject.