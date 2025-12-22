# MR_RayBan_Meta

Developing Moyne Roberts applications for the Ray-Ban Meta Wayfarer Gen 2 glasses with iPhone 14 Pro integration.

## Overview

This repository contains proof of concept implementations for the Ray-Ban Meta smart glasses platform. The POCs demonstrate various capabilities including voice control, camera integration, AI vision, and live streaming.

## Ray-Ban Meta Wayfarer Gen 2 Specifications

| Feature | Specification |
|---------|---------------|
| Camera | 12MP Ultra-wide camera |
| Video | 1080p @ 30fps, 720p @ 30fps |
| Audio | 5-microphone array, open-ear speakers |
| Storage | 32GB internal |
| Battery | Up to 4 hours continuous use |
| Connectivity | Bluetooth 5.2, WiFi |
| AI Assistant | Meta AI built-in |

## Project Structure

```
MR_RayBan_Meta/
├── docs/                          # Documentation
│   ├── CAPABILITIES.md            # Glasses capabilities reference
│   ├── IPHONE_SETUP.md            # iPhone 14 Pro setup guide
│   └── API_REFERENCE.md           # API and integration reference
├── ios-companion-app/             # iOS companion app (Swift/SwiftUI)
│   └── RayBanMetaCompanion/       # Xcode project
├── pocs/                          # Proof of Concept implementations
│   ├── voice-assistant/           # Voice command POC
│   ├── photo-capture/             # Photo capture & processing POC
│   ├── live-stream/               # Live streaming POC
│   └── ai-vision/                 # AI vision & object detection POC
├── scripts/                       # Utility scripts
└── assets/                        # Shared assets
```

## Prerequisites

### Hardware
- Ray-Ban Meta Wayfarer Gen 2 glasses
- iPhone 14 Pro (iOS 16.0+)
- Mac with Xcode 15+ (for iOS development)

### Software
- Meta View app (App Store)
- WhatsApp (optional, for messaging features)
- Facebook/Instagram app (for live streaming)

## Quick Start

1. **Pair your glasses**: Download Meta View app and follow pairing instructions
2. **Clone this repository**: `git clone <repo-url>`
3. **Open iOS project**: Open `ios-companion-app/RayBanMetaCompanion.xcodeproj` in Xcode
4. **Run on device**: Build and run on your iPhone 14 Pro

## POC Descriptions

### 1. Voice Assistant POC
Demonstrates voice command integration using "Hey Meta" wake word and custom voice actions.

### 2. Photo Capture POC
Shows camera integration for capturing photos, processing them on iPhone, and triggering actions.

### 3. Live Stream POC
Implements live streaming workflows to Facebook/Instagram with companion app control.

### 4. AI Vision POC
Explores Meta AI vision capabilities for object recognition and scene understanding.

## Development Notes

- The Ray-Ban Meta glasses communicate with iPhone via Bluetooth
- Media is synced through the Meta View app
- Custom integrations require building companion apps that work alongside Meta View
- Voice commands use "Hey Meta" wake word

## License

Proprietary - Moyne Roberts © 2024
