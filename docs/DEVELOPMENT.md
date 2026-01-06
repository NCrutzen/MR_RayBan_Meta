# Development Environment Setup

Complete guide for setting up your development environment for Ray-Ban Meta glasses POC development.

## Prerequisites

### Hardware
- **Mac**: macOS Ventura 13.0+ or Sonoma 14.0+
- **iPhone 14 Pro**: iOS 16.0+ (for testing)
- **Ray-Ban Meta Wayfarer Gen 2**: Paired with iPhone

### Software
- **Xcode 15+**: Download from Mac App Store
- **Command Line Tools**: `xcode-select --install`
- **Git**: Usually included with Command Line Tools

## Quick Setup

```bash
# 1. Clone the repository
git clone <repo-url>
cd MR_RayBan_Meta

# 2. Open iOS project in Xcode
open ios-companion-app/RayBanMetaCompanion.xcodeproj

# 3. Configure signing in Xcode
# - Select project in navigator
# - Go to Signing & Capabilities
# - Set your Team
# - Update Bundle Identifier if needed
```

## Xcode Configuration

### 1. Select Development Team

1. Open `RayBanMetaCompanion.xcodeproj`
2. Select the project in the navigator
3. Select the target "RayBanMetaCompanion"
4. Go to "Signing & Capabilities" tab
5. Choose your development team

### 2. Bundle Identifier

Update the bundle identifier to match your team:
```
com.yourcompany.raybanmeta.companion
```

### 3. Capabilities

Ensure these capabilities are enabled:
- Background Modes
  - Uses Bluetooth LE accessories
  - Background fetch
  - Background processing

### 4. Run on Device

1. Connect iPhone 14 Pro via USB
2. Select device in Xcode toolbar
3. Click Run (⌘R)
4. Trust developer on iPhone if prompted

## iPhone Configuration

### Enable Developer Mode (iOS 16+)

1. Settings → Privacy & Security → Developer Mode
2. Toggle ON
3. Restart when prompted
4. Confirm after restart

### Pair Ray-Ban Meta Glasses

1. Install Meta View app from App Store
2. Follow pairing instructions in app
3. Grant all requested permissions

## Project Structure

```
MR_RayBan_Meta/
├── docs/                       # Documentation
├── ios-companion-app/          # Main iOS app
│   ├── RayBanMetaCompanion/    # Source files
│   │   ├── Sources/
│   │   │   ├── App/            # App entry point
│   │   │   ├── Views/          # SwiftUI views
│   │   │   ├── ViewModels/     # View models
│   │   │   ├── Services/       # Business logic
│   │   │   ├── Models/         # Data models
│   │   │   └── Extensions/     # Swift extensions
│   │   ├── Resources/          # Assets, localization
│   │   └── Info.plist          # App configuration
│   └── RayBanMetaCompanion.xcodeproj
├── pocs/                       # Proof of concepts
│   ├── voice-assistant/
│   ├── photo-capture/
│   ├── ai-vision/
│   └── live-stream/
├── scripts/                    # Utility scripts
└── assets/                     # Shared assets
```

## Testing

### Simulator Limitations

The iOS Simulator cannot:
- Access real Bluetooth devices
- Receive photos from glasses
- Test Core Bluetooth functionality

Use simulator only for UI development.

### Physical Device Testing

Required for:
- Bluetooth connection testing
- Photo library integration
- Vision/CoreML processing
- Background mode testing

### Test Workflow

1. Pair glasses with Meta View app
2. Capture test photos with glasses
3. Ensure photos sync to Photos app
4. Run companion app
5. Verify photo detection and processing

## Debugging

### Console Logging

```swift
import os

let logger = Logger(subsystem: "com.moyenroberts.raybanmeta", category: "general")

// Usage
logger.debug("Debug message")
logger.info("Info message")
logger.error("Error message")
```

### Bluetooth Debugging

1. Enable Bluetooth logging in Xcode
2. Use Console.app to view system Bluetooth logs
3. Filter by "CoreBluetooth" or "Bluetooth"

### Photo Library Debugging

```swift
// Check authorization status
PHPhotoLibrary.authorizationStatus(for: .readWrite)

// Request access
PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
    print("Photo library status: \(status)")
}
```

## Common Issues

### "Code Signing Error"

1. Verify Apple Developer account is active
2. Check Team selection in Xcode
3. Ensure bundle ID is unique
4. Clean build folder (⌘⇧K)

### "Could not launch"

1. Ensure Developer Mode is enabled on iPhone
2. Trust the developer certificate
3. Check USB connection
4. Restart iPhone if needed

### "Photos Not Syncing"

1. Check WiFi connection
2. Open Meta View app (sync requires it running)
3. Wait 30-60 seconds after capture
4. Force sync in Meta View settings

### "Bluetooth Not Finding Glasses"

1. Check glasses are charged and powered on
2. Ensure Bluetooth is enabled on iPhone
3. Check glasses aren't connected to another device
4. Reset Bluetooth (toggle off/on)

## Code Style

### SwiftUI Best Practices

```swift
// Prefer property wrappers
@StateObject private var viewModel = ViewModel()
@EnvironmentObject var manager: Manager

// Extract subviews
struct MyView: View {
    var body: some View {
        VStack {
            HeaderView()
            ContentView()
            FooterView()
        }
    }
}
```

### Async/Await

```swift
// Use modern concurrency
func processPhoto() async throws -> Result {
    let image = try await loadImage()
    let result = try await analyzeImage(image)
    return result
}

// Call from SwiftUI
.task {
    do {
        result = try await processPhoto()
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

## Resources

### Apple Documentation
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [Core ML](https://developer.apple.com/documentation/coreml)
- [PhotoKit](https://developer.apple.com/documentation/photokit)
- [Core Bluetooth](https://developer.apple.com/documentation/corebluetooth)

### Meta Resources
- [Ray-Ban Meta Product Page](https://www.ray-ban.com/meta)
- [Meta View App](https://apps.apple.com/app/meta-view/id1613849498)

## Getting Help

- Check existing POC implementations for examples
- Review Apple's sample code projects
- File issues in the repository for bugs
