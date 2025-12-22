# Voice Assistant POC

Demonstrates voice command integration with Ray-Ban Meta glasses using Meta AI and iOS automation.

## Overview

Since the Ray-Ban Meta glasses use "Hey Meta" as the wake word and don't support custom wake words, this POC focuses on:

1. **Post-capture processing**: Detect when voice commands trigger actions (photos, videos)
2. **iOS Shortcuts integration**: Create automations that enhance voice command capabilities
3. **Notification handling**: Process and respond to Meta AI notifications

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 Ray-Ban Meta Glasses                         │
│                                                              │
│   User: "Hey Meta, take a photo"                            │
│                    │                                         │
│                    ▼                                         │
│   ┌────────────────────────────────────┐                    │
│   │   Meta AI processes command        │                    │
│   │   Camera captures photo            │                    │
│   └────────────────────────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
                              │
                     Photo syncs via WiFi
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      iPhone                                  │
│                                                              │
│   ┌────────────────────────────────────┐                    │
│   │   Meta View App receives photo     │                    │
│   │   Syncs to Photos library          │                    │
│   └────────────────────────────────────┘                    │
│                    │                                         │
│                    ▼                                         │
│   ┌────────────────────────────────────┐                    │
│   │   PHPhotoLibraryChangeObserver     │                    │
│   │   detects new photo                │                    │
│   └────────────────────────────────────┘                    │
│                    │                                         │
│                    ▼                                         │
│   ┌────────────────────────────────────┐                    │
│   │   Companion App processes photo    │                    │
│   │   - OCR extraction                 │                    │
│   │   - Object detection               │                    │
│   │   - Custom actions                 │                    │
│   └────────────────────────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

## Supported Voice Commands

| Command | Native Action | POC Enhancement |
|---------|--------------|-----------------|
| "Hey Meta, take a photo" | Captures photo | Auto-process with Vision AI |
| "Hey Meta, start recording" | Records video | Monitor and process video |
| "Hey Meta, what am I looking at?" | Meta AI describes scene | Cache results for later |
| "Hey Meta, read this" | OCR via Meta AI | Extract and save text |

## Implementation

### 1. Photo Library Observer

```swift
// Detects new photos from glasses
PHPhotoLibrary.shared().register(self)

func photoLibraryDidChange(_ change: PHChange) {
    // Check for new assets from glasses
    // Trigger processing pipeline
}
```

### 2. iOS Shortcuts

Create shortcuts for enhanced voice workflows:

**Shortcut: "Process Glasses Photo"**
1. Get latest photo from library
2. Run Vision OCR
3. Copy text to clipboard
4. Show notification

**Shortcut: "Glasses Quick Note"**
1. Trigger with "Hey Siri, glasses note"
2. Start voice recording
3. Transcribe and save to Notes

### 3. Notification Actions

```swift
// Register for actionable notifications
UNUserNotificationCenter.current().setNotificationCategories([
    UNNotificationCategory(
        identifier: "GLASSES_PHOTO",
        actions: [
            UNNotificationAction(identifier: "PROCESS", title: "Process with AI"),
            UNNotificationAction(identifier: "SHARE", title: "Quick Share")
        ],
        intentIdentifiers: []
    )
])
```

## Files

- `VoiceCommandHandler.swift` - Core voice command processing logic
- `PhotoWatcher.swift` - Monitors photo library for new captures
- `ShortcutsIntegration.swift` - iOS Shortcuts app intent definitions

## Usage

1. Pair glasses with iPhone via Meta View app
2. Install companion app
3. Grant photo library permissions
4. Use voice commands as normal - enhancements happen automatically

## Limitations

- Cannot intercept voice commands before Meta AI processes them
- Custom wake words not supported
- Real-time audio streaming not available
- Relies on photo sync delay (1-5 seconds typical)
