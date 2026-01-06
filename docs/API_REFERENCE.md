# API Reference & Integration Guide

## Overview

As of 2024, Meta does not provide a public SDK for direct Ray-Ban Meta glasses programming. This guide documents available integration approaches for building companion apps and automations.

## Integration Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Ray-Ban Meta Glasses                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Camera    │  │    Audio    │  │     Meta AI         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                    Bluetooth / WiFi
                              │
┌─────────────────────────────────────────────────────────────┐
│                     iPhone 14 Pro                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Meta View   │  │   Photos    │  │   Custom Apps       │  │
│  │    App      │  │   Library   │  │  (Companion)        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Shortcuts  │  │  HealthKit  │  │    CloudKit         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## iOS Frameworks for Integration

### PhotoKit (Photos Framework)

Access media captured by glasses after sync.

```swift
import Photos

class GlassesMediaManager {

    /// Fetch recent photos from glasses (synced via Meta View)
    func fetchRecentGlassesPhotos(limit: Int = 50) async throws -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = limit

        // Filter by source - glasses photos have specific metadata
        let results = PHAsset.fetchAssets(with: .image, options: options)

        var assets: [PHAsset] = []
        results.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    /// Monitor for new photos (glasses captures)
    func startMonitoring() {
        PHPhotoLibrary.shared().register(self)
    }
}

extension GlassesMediaManager: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Handle new photos from glasses
    }
}
```

### Core Bluetooth

Monitor glasses connection status.

```swift
import CoreBluetooth

class GlassesConnectionManager: NSObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager!

    // Known Ray-Ban Meta service UUIDs (unofficial, may change)
    private let glassesServiceUUID = CBUUID(string: "YOUR-SERVICE-UUID")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Scan for glasses
            central.scanForPeripherals(withServices: [glassesServiceUUID])
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        // Handle discovered glasses
        print("Found glasses: \(peripheral.name ?? "Unknown")")
    }
}
```

### iOS Shortcuts Integration

Create shortcuts that respond to glasses events.

```swift
import Intents

class CapturePhotoIntent: INIntent {
    // Define custom intent for shortcuts
}

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        // Handle shortcut triggers
        return self
    }
}
```

### Background Processing

Process glasses media in background.

```swift
import BackgroundTasks

class BackgroundMediaProcessor {

    static let taskIdentifier = "com.moyenroberts.glasses.mediaprocessing"

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundTask(task: task as! BGProcessingTask)
        }
    }

    func scheduleBackgroundProcessing() {
        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleBackgroundTask(task: BGProcessingTask) {
        // Process synced glasses media
        task.setTaskCompleted(success: true)
    }
}
```

## Vision Framework Integration

Process photos from glasses using Apple's Vision framework.

```swift
import Vision
import UIKit

class GlassesVisionProcessor {

    /// Detect objects in glasses photo
    func detectObjects(in image: UIImage) async throws -> [VNRecognizedObjectObservation] {
        guard let cgImage = image.cgImage else {
            throw ProcessingError.invalidImage
        }

        let request = VNRecognizeAnimalsRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        return request.results ?? []
    }

    /// Extract text from glasses photo
    func extractText(from image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw ProcessingError.invalidImage
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        return request.results?.compactMap {
            $0.topCandidates(1).first?.string
        } ?? []
    }

    /// Detect faces for POC applications
    func detectFaces(in image: UIImage) async throws -> [VNFaceObservation] {
        guard let cgImage = image.cgImage else {
            throw ProcessingError.invalidImage
        }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        return request.results ?? []
    }
}

enum ProcessingError: Error {
    case invalidImage
    case processingFailed
}
```

## Core ML Integration

Use custom ML models with glasses photos.

```swift
import CoreML
import Vision

class CustomModelProcessor {

    private var model: VNCoreMLModel?

    init(modelName: String) throws {
        let config = MLModelConfiguration()
        // Load your custom Core ML model
        // let customModel = try YourCustomModel(configuration: config)
        // self.model = try VNCoreMLModel(for: customModel.model)
    }

    func classify(image: UIImage) async throws -> [VNClassificationObservation] {
        guard let model = model,
              let cgImage = image.cgImage else {
            throw ProcessingError.invalidImage
        }

        let request = VNCoreMLRequest(model: model)
        let handler = VNImageRequestHandler(cgImage: cgImage)

        try handler.perform([request])

        return request.results as? [VNClassificationObservation] ?? []
    }
}
```

## Network Integration

Send glasses data to backend services.

```swift
import Foundation

class GlassesAPIClient {

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL) {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }

    /// Upload glasses photo for processing
    func uploadPhoto(imageData: Data, metadata: PhotoMetadata) async throws -> UploadResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("/api/photos"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = UploadRequest(
            imageBase64: imageData.base64EncodedString(),
            metadata: metadata
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(UploadResponse.self, from: data)
    }
}

struct PhotoMetadata: Codable {
    let timestamp: Date
    let location: String?
    let deviceModel: String
}

struct UploadRequest: Codable {
    let imageBase64: String
    let metadata: PhotoMetadata
}

struct UploadResponse: Codable {
    let id: String
    let status: String
}
```

## Push Notifications

Trigger actions based on server events.

```swift
import UserNotifications

class NotificationManager {

    func requestPermission() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted
    }

    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func handleNotification(_ notification: [String: Any]) {
        // Handle push notification from backend
        // Could trigger glasses-related actions
    }
}
```

## Limitations & Considerations

### What's NOT Possible
- Direct firmware access or modification
- Custom wake words (only "Hey Meta")
- Real-time camera feed streaming to app
- Direct Bluetooth control commands to glasses
- Accessing raw sensor data

### What IS Possible
- Access synced photos/videos via Photos framework
- Monitor Bluetooth connection status
- Create iOS Shortcuts for automation
- Process media with Vision/Core ML
- Build companion apps that enhance the glasses experience

## Best Practices

1. **Respect Privacy**: Always inform users about data processing
2. **Battery Awareness**: Minimize background processing
3. **Graceful Degradation**: Handle cases when glasses aren't connected
4. **Sync Timing**: Account for delay between capture and sync
5. **Error Handling**: Meta View app may not always be running

## Future Considerations

Meta may release official SDK in the future. Monitor:
- Meta Developer Portal
- Meta Quest Developer documentation
- Ray-Ban Meta product updates
