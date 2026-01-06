# Live Stream POC

Demonstrates companion app features for enhancing Ray-Ban Meta glasses live streaming to Facebook and Instagram.

## Overview

The Ray-Ban Meta glasses support native live streaming to Facebook Live and Instagram Live. This POC explores how a companion app can enhance the streaming experience.

## Features

### 1. Stream Dashboard
- View current stream status
- Monitor viewer count (via API)
- See incoming comments

### 2. Comment Overlay
- Display comments as notifications
- Text-to-speech for important comments
- Filter/moderate comments

### 3. Stream Controls
- Start/stop reminders
- Stream duration timer
- Battery monitoring alerts

### 4. Post-Stream Analytics
- View archived streams
- Engagement metrics
- Highlight clips

## Limitations

Since the glasses handle streaming directly:
- Cannot modify the video feed
- Cannot add overlays to the stream itself
- Control is limited to what Meta View provides
- API access requires Meta developer account

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Ray-Ban Meta Glasses                       │
│                                                              │
│   "Hey Meta, go live on Instagram"                          │
│              │                                               │
│              ▼                                               │
│   ┌────────────────────┐                                    │
│   │  Native Streaming  │ ───────────────────┐               │
│   │  (1080p/720p)      │                    │               │
│   └────────────────────┘                    │               │
└─────────────────────────────────────────────┼───────────────┘
                                              │
                                              ▼
                                    ┌─────────────────┐
                                    │   Facebook/     │
                                    │   Instagram     │
                                    │   Servers       │
                                    └─────────────────┘
                                              │
                      ┌───────────────────────┼───────────────┐
                      │                       │               │
                      ▼                       ▼               ▼
            ┌─────────────────┐     ┌─────────────────┐  ┌─────────┐
            │  Companion App  │     │   Viewers       │  │  API    │
            │                 │     │                 │  │         │
            │  - Comments     │◄────│  - Watch        │  │         │
            │  - Analytics    │     │  - Comment      │  │         │
            │  - Alerts       │     │  - React        │  │         │
            └─────────────────┘     └─────────────────┘  └─────────┘
```

## API Integration

### Facebook Graph API
```swift
// Get live video info
let endpoint = "https://graph.facebook.com/v18.0/{video-id}"
let params = ["fields": "live_views,comments"]

// Requires user access token with:
// - pages_read_engagement
// - pages_manage_posts
// - publish_video
```

### Instagram Graph API
```swift
// Get live media insights
let endpoint = "https://graph.facebook.com/v18.0/{ig-media-id}/insights"

// Requires Instagram Business/Creator account
```

## Implementation

### Stream Status Monitor
```swift
class StreamMonitor: ObservableObject {
    @Published var isLive = false
    @Published var viewerCount = 0
    @Published var duration: TimeInterval = 0
    @Published var comments: [StreamComment] = []

    func startMonitoring(videoId: String) {
        // Poll API for updates
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.fetchStatus(videoId: videoId)
        }
    }
}
```

### Comment Handler
```swift
class CommentHandler {
    func processComment(_ comment: StreamComment) {
        // Filter inappropriate content
        guard !containsProfanity(comment.text) else { return }

        // Notify via audio if important
        if comment.isFromModerator || comment.containsMention {
            speakComment(comment)
        }

        // Add to display queue
        displayQueue.append(comment)
    }
}
```

## Files

- `StreamMonitor.swift` - Monitors stream status
- `CommentOverlay.swift` - Displays comments
- `StreamDashboardView.swift` - UI for stream controls
- `AnalyticsView.swift` - Post-stream analytics

## Setup

1. Create Meta Developer account
2. Register app on Facebook Developers portal
3. Request necessary permissions
4. Configure OAuth flow
5. Store access tokens securely

## Use Cases

### Personal Streaming
- Share experiences hands-free
- No need to hold phone
- Natural perspective

### Professional Use
- Field reporting
- Behind-the-scenes content
- Live product demos

### Events
- Concerts and festivals
- Sports events
- Travel vlogs

## Privacy Considerations

- Respect recording laws in your jurisdiction
- Inform people when streaming
- LED indicator shows when camera is active
- Consider who might be in frame
