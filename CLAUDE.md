# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Captionize is an iOS video editor app built with SwiftUI that allows users to add customizable text captions to videos from their photo library. The app supports precise caption timing, custom positioning, text styling, and exports the captioned video back to the photo library.

## Build and Run Commands

### Building the Project
```bash
xcodebuild -project Captionize.xcodeproj -scheme Captionize -configuration Debug build
```

### Running on Simulator
```bash
xcodebuild -project Captionize.xcodeproj -scheme Captionize -destination 'platform=iOS Simulator,name=iPhone 15' clean build
```

### Clean Build
```bash
xcodebuild -project Captionize.xcodeproj -scheme Captionize clean
```

Note: The project is configured for iOS development and requires Xcode. There are no external package dependencies (no CocoaPods, SPM, or Carthage).

## Architecture

### Core Data Stack
- **MyProjectsProvider**: Singleton managing the Core Data persistent container (`Projects.xcdatamodeld`)
- **Entities**:
  - `MyProject`: Stores video asset references (PHAsset ID) and relationships to captions and text configuration
  - `Caption`: Individual caption segments with text, timing (startPoint/endPoint), colors (hex strings), and position (normalized 0.0-1.0 coordinates)
  - `TextConfiguration`: Global text styling (font name, size, alignment) per project

### Video Editor Architecture

The video editor follows a ViewModel-based architecture with distinct responsibilities:

#### VideoEditorViewModel
Central state manager coordinating video playback, caption management, and export. Contains three nested state structures:
- **VideoEditorStates**: UI states (isLoaded, isPlaying, isAutoScrolling, etc.)
- **VideoPlayerConfig**: AVPlayer instance, current time, duration, video dimensions
- **CaptionsConfig**: Array of `CaptionItem`, time markers, selected editor mode, and caption styling

Key responsibilities:
- Managing AVPlayer lifecycle with periodic time observers (timescale: 40000 for precision)
- Caption collision detection (`checkAvailibility()`) - prevents overlapping captions with minimum width constraints
- Timeline manipulation (adding/removing captions, adjusting start/end points via drag)
- Text capitalization transforms (AB/Ab/ab modes applied to all captions)

#### Video Player Components
- **VideoPlayer (UIViewControllerRepresentable)**: Bridges AVPlayerViewController to SwiftUI
  - Manages UILabel overlay for live caption preview
  - Handles tap-to-pause and pan-to-position gestures
  - Uses KVO to track videoBounds changes for proper caption positioning
  - Maintains a high-frequency time observer for smooth caption display updates

- **VideoPlayerView**: SwiftUI wrapper providing play/pause controls and end-of-video handling

#### VideoExportManager
Handles AVFoundation composition and export:
- Creates `AVMutableComposition` with video and audio tracks
- Builds `AVMutableVideoComposition` with `CATextLayer` overlays for each caption
- Calculates absolute font sizes by scaling reference font size to video natural size
- Supports custom caption positioning (normalized coordinates) and default bottom placement
- Exports to temporary directory then saves to photo library via `PHPhotoLibrary`
- Uses `AVAssetExportPresetHighestQuality` (simulator uses passthrough preset)

### Video Library Integration
- **VideoLibrary protocol**: Abstraction for fetching video albums (allows for testing/mocking)
- **DefaultVideoLibrary**:
  - Fetches PHAsset collections (smart albums + user albums)
  - Filters albums containing videos
  - Creates thumbnail images (400x400) for video grid display
  - Uses DispatchGroup for coordinating async photo library requests
  - Always includes "All Videos" album as first item

### Caption Timeline System
Captions are positioned on a timeline where:
- Time is converted to points: `secondToPoint = 124.0` (defined in Constants.VECap)
- Minimum caption width: `minWidth = secondToPoint / 2` (0.5 seconds)
- Spacing between adjacent captions: `1.0` point
- **Timeline offset**: The center indicator represents `currentTime + 0.5` seconds (playhead position)
- **Synchronized display**: Both timeline and video player use the same 0.5s offset for caption display
- Drag interactions update startPoint/endPoint with collision detection to prevent overlap
- UI uses a horizontal ScrollView with rectangles representing caption segments

### Navigation Flow
1. **MyProjectView**: Grid of saved projects with thumbnails (managed by MyProjectsViewModel)
2. **PickVideoView**: Album and video selection from photo library (PickVideoViewModel)
3. **VideoEditorContainerView**: Main editor with video player, timeline, and configuration panels
4. **Export**: Renders video with captions and saves to photo library

### Important Constants (Constants.swift)
- `VECap` (Video Editor Caption): Timeline layout constants (spacing, minimum widths, heights)
- `VPCap` (Video Player Caption):
  - `timescale: 40000` - High precision for accurate seeking and export
  - `uiTickPerSecond: 15` - Throttled UI updates to reduce overhead
- `VETextSettings`: Configuration panel cell dimensions (35% of screen height)

### Key Extensions
- **Double/CGFloat/TimeInterval**: Conversion utilities between seconds, points, and time formats
- **Binding**: Utility extensions for two-way data flow in SwiftUI
- **CGColor**: Hex string parsing for per-caption color customization
- **UIScreen**: Percentage-based layout calculations

## Development Guidelines

### Working with Captions
- Caption positions are stored as normalized coordinates (0.0 to 1.0) in both X and Y
- Negative position values (-1) indicate default positioning should be used
- The timeline uses a point-based system separate from actual time values
- Always use the defined timescale (40000) when working with CMTime for consistency

### Core Data Operations
- All Core Data operations go through MyProjectsProvider
- Use `persist(in:)` to save changes
- Use `exisits(_:in:)` before deleting to ensure object is in the correct context
- The app uses `.mergeByPropertyObjectTrump` merge policy

### Video Export Considerations
- Exports happen in a background Task
- Font sizes must be scaled from UI reference size to video natural size
- Portrait videos require swapping width/height dimensions
- The simulator uses passthrough preset to avoid hardware encoding issues
- Export saves to temporary directory first, then moves to photo library

### Localization
The app is configured for Armenian locale ("hy") but displays English strings with localization support via `String(localized:)`.

## Common Tasks

### Adding a New Caption Property
1. Update `CaptionItem` struct in Captionize/Views/VideoEditor/Editor/EditorCaption/CaptionItem.swift
2. Update Core Data entity `Caption` in Projects.xcdatamodeld
3. Update `Caption+CoreDataProperties.swift`
4. Modify `MyProjectsViewModel.fetchCaptions()` to map the new property
5. Update `VideoExportManager.newCaptionTextLayerWith()` to apply the property during export

### Modifying Timeline Behavior
Timeline logic is primarily in VideoEditorViewModel:
- `udpatePoints(for:x:)` - Handles drag interactions
- `setLeftPoint()` / `setRightPoint()` - Enforces constraints during dragging
- `checkAvailibility()` - Determines if captions can be added/removed at current time

### Debugging Video Playback
- Check `playerConfig.player.status` - should be `.readyToPlay` before seeking
- Verify `timeObserverToken` is properly set up and removed in deinit
- The player uses precise seeking with zero tolerance for frame-accurate positioning
- Auto-scrolling is tied to `editorStates.isAutoScrolling` state