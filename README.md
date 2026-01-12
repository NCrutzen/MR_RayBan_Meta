# Meta Glasses Camera

An iOS app for streaming video and capturing photos from Ray-Ban Meta smart glasses using Meta's official Wearables Device Access Toolkit (MWDAT).

## Features

- **Live Video Streaming**: Stream video directly from your Ray-Ban Meta glasses camera to your iPhone
- **Photo Capture**: Take photos from your glasses with a single tap
- **Time-Limited Streaming**: Set streaming duration limits (1, 5, 10, or 15 minutes)
- **Device Management**: Connect, disconnect, and manage your Meta glasses
- **Mock Device Support**: Test the app in debug mode without physical hardware

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.0+
- Ray-Ban Meta glasses (Gen 1 or Gen 2) for production use
- Meta AI app installed on your iPhone

## Supported Devices

- Ray-Ban Meta Wayfarer (Gen 1 & Gen 2)
- Ray-Ban Meta Headliner (Gen 1 & Gen 2)
- Oakley Meta HSTN

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/NCrutzen/MR_RayBan_Meta.git
cd MR_RayBan_Meta
```

### 2. Open in Xcode

```bash
open MetaGlassesCamera.xcodeproj
```

### 3. Configure Signing

1. Select the `MetaGlassesCamera` target
2. Go to "Signing & Capabilities"
3. Select your Development Team
4. Update the Bundle Identifier if needed

### 4. Register Your App (For Production)

To use the app with real glasses:

1. Visit the [Meta Wearables Developer Center](https://wearables.developer.meta.com)
2. Register your app and get your `MetaAppID` and `ClientToken`
3. Update the `Info.plist` with your credentials:

```xml
<key>MWDAT</key>
<dict>
    <key>MetaAppID</key>
    <string>YOUR_META_APP_ID</string>
    <key>ClientToken</key>
    <string>YOUR_CLIENT_TOKEN</string>
    <key>TeamID</key>
    <string>YOUR_APPLE_TEAM_ID</string>
</dict>
```

### 5. Build and Run

Build the project in Xcode and run on your iPhone.

## Usage

### Connecting to Glasses

1. Launch the app
2. Tap "Connect my glasses"
3. You'll be redirected to the Meta AI app to confirm the connection
4. Return to the app once connected

### Streaming Video

1. Once connected, tap "Start streaming"
2. Grant camera permissions when prompted
3. View the live video feed from your glasses
4. Use the timer button to set streaming limits
5. Tap the camera button to capture photos
6. Tap "Stop streaming" to end the session

### Debug Mode (Mock Device)

For development without physical glasses:

1. Build in Debug configuration
2. Tap the debug button (ladybug icon)
3. Pair a mock Ray-Ban Meta device
4. Power on and configure the mock device
5. Select mock video/image content for testing

## Project Structure

```
MetaGlassesCamera/
├── Sources/
│   ├── App/
│   │   └── MetaGlassesCameraApp.swift    # App entry point
│   ├── ViewModels/
│   │   ├── WearablesViewModel.swift      # Device management
│   │   ├── StreamSessionViewModel.swift  # Streaming logic
│   │   ├── DebugMenuViewModel.swift      # Debug controls
│   │   └── MockDeviceKit/                # Mock device VMs
│   ├── Views/
│   │   ├── MainAppView.swift             # Navigation hub
│   │   ├── HomeScreenView.swift          # Welcome/connect screen
│   │   ├── StreamSessionView.swift       # Streaming container
│   │   ├── StreamView.swift              # Active streaming UI
│   │   ├── NonStreamView.swift           # Pre-streaming UI
│   │   ├── Components/                   # Reusable components
│   │   └── MockDeviceKit/                # Debug UI
│   └── Utils/
│       ├── TimeUtils.swift               # Timer utilities
│       └── ColorExtensions.swift         # Theme colors
├── Assets.xcassets/                      # App assets
└── Info.plist                            # App configuration
```

## Dependencies

This project uses Meta's official SDK via Swift Package Manager:

- **MWDATCore**: Core SDK for device management and registration
- **MWDATCamera**: Camera streaming and photo capture functionality
- **MWDATMockDevice**: Mock device kit for testing (Debug only)

Package URL: `https://github.com/facebook/meta-wearables-dat-ios`

## Technical Details

### Camera Capabilities

- Maximum streaming resolution: 720p
- Maximum frame rate: 30 FPS (reduced when Bluetooth bandwidth is limited)
- Photo capture format: JPEG

### Permissions Required

- **Bluetooth**: For connecting to Meta glasses
- **Photo Library**: For saving captured photos

## Resources

- [Meta Wearables Developer Center](https://wearables.developer.meta.com)
- [Meta Wearables DAT iOS SDK](https://github.com/facebook/meta-wearables-dat-ios)
- [Getting Started Guide](https://wearables.developer.meta.com/docs/getting-started-toolkit/)

## License

This project is based on Meta's sample code and is subject to their licensing terms.

## Acknowledgments

Built using the [Meta Wearables Device Access Toolkit](https://developers.meta.com/wearables/).
