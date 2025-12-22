# Photo Capture POC

Demonstrates advanced photo processing capabilities for images captured with Ray-Ban Meta glasses.

## Overview

This POC showcases how to build intelligent photo processing pipelines that automatically analyze images captured by the glasses.

## Features

### 1. Automatic OCR (Text Extraction)
- Extracts text from photos of documents, signs, business cards
- Supports multiple languages
- Copies text to clipboard or saves to notes

### 2. Object Detection
- Identifies objects in the scene
- Uses Apple's Vision framework and custom Core ML models
- Provides confidence scores

### 3. Barcode/QR Scanning
- Detects QR codes and barcodes
- Automatically opens URLs
- Saves product information

### 4. Face Detection
- Detects faces in photos
- Counts number of people
- Optional: Face landmarks for analysis

### 5. Document Scanning
- Detects document boundaries
- Applies perspective correction
- Enhances for readability

## Usage

### Automatic Processing
```swift
// In your app, register for photo library changes
mediaManager.onNewPhoto { asset in
    let processor = PhotoCaptureProcessor()
    let results = await processor.process(asset)

    // Handle results
    if !results.extractedText.isEmpty {
        // Show text extraction notification
    }
}
```

### Manual Processing
```swift
let processor = PhotoCaptureProcessor()

// Process specific image
let results = await processor.process(image)

// Access results
print("Text: \(results.extractedText)")
print("Objects: \(results.detectedObjects)")
print("Barcodes: \(results.barcodes)")
```

## Files

- `PhotoCaptureProcessor.swift` - Main processing pipeline
- `DocumentScanner.swift` - Document detection and enhancement
- `ResultsView.swift` - UI for displaying results

## Architecture

```
Photo from Glasses
        │
        ▼
┌───────────────────┐
│  Photo Library    │
│  Observer         │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│  Processing       │
│  Queue            │
└───────────────────┘
        │
        ├──────────────────┬──────────────────┐
        ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│  OCR          │  │  Object       │  │  Barcode      │
│  Pipeline     │  │  Detection    │  │  Scanner      │
└───────────────┘  └───────────────┘  └───────────────┘
        │                  │                  │
        └──────────────────┴──────────────────┘
                          │
                          ▼
                ┌───────────────────┐
                │  Results          │
                │  Aggregator       │
                └───────────────────┘
                          │
                          ▼
                ┌───────────────────┐
                │  Action           │
                │  Dispatcher       │
                └───────────────────┘
```

## Configuration

```swift
struct ProcessingConfig {
    var enableOCR = true
    var enableObjectDetection = true
    var enableBarcodeScanning = true
    var enableFaceDetection = false // Privacy consideration
    var enableDocumentScanning = true

    var ocrLanguages: [String] = ["en-US"]
    var minConfidence: Float = 0.5
}
```

## Best Practices

1. **Process in background**: Use background tasks for processing
2. **Respect privacy**: Ask before enabling face detection
3. **Battery awareness**: Limit processing frequency
4. **User control**: Allow disabling specific features
