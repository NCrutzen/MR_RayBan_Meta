# AI Vision POC

Explores advanced AI-powered vision capabilities for Ray-Ban Meta glasses using Core ML and Vision frameworks.

## Overview

This POC demonstrates how to leverage Apple's machine learning frameworks to create intelligent visual processing pipelines for glasses-captured images.

## Features

### 1. Scene Classification
Automatically categorize scenes (indoor, outdoor, restaurant, office, etc.)

### 2. Object Recognition
Identify and locate specific objects in the frame.

### 3. Image Segmentation
Separate foreground from background for advanced processing.

### 4. Depth Estimation
Estimate relative depth in scenes (using monocular depth models).

### 5. Custom Model Integration
Load and run custom Core ML models for specialized tasks.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AI Vision Pipeline                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Image Input                                                │
│       │                                                      │
│       ▼                                                      │
│   ┌─────────────────┐                                       │
│   │  Preprocessing  │ ─── Resize, normalize, format         │
│   └─────────────────┘                                       │
│       │                                                      │
│       ├─────────────────────────────────────┐               │
│       ▼                                     ▼               │
│   ┌─────────────────┐           ┌─────────────────┐        │
│   │ Vision Request  │           │  Core ML Model  │        │
│   │   Handler       │           │     Inference   │        │
│   └─────────────────┘           └─────────────────┘        │
│       │                                     │               │
│       ▼                                     ▼               │
│   ┌─────────────────┐           ┌─────────────────┐        │
│   │ Built-in Vision │           │  Custom Model   │        │
│   │   Features      │           │    Results      │        │
│   └─────────────────┘           └─────────────────┘        │
│       │                                     │               │
│       └─────────────────────────────────────┘               │
│                         │                                    │
│                         ▼                                    │
│               ┌─────────────────┐                           │
│               │  Result Fusion  │                           │
│               └─────────────────┘                           │
│                         │                                    │
│                         ▼                                    │
│               ┌─────────────────┐                           │
│               │  Action Engine  │                           │
│               └─────────────────┘                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Available Models

### Built-in (Vision Framework)
- VNClassifyImageRequest - Scene/object classification
- VNDetectFaceRectanglesRequest - Face detection
- VNRecognizeTextRequest - OCR
- VNDetectBarcodesRequest - Barcode/QR
- VNGenerateAttentionBasedSaliencyImageRequest - Saliency

### Core ML Models (Downloadable)
| Model | Size | Use Case |
|-------|------|----------|
| MobileNetV2 | 25 MB | Object classification |
| YOLOv3 | 62 MB | Real-time object detection |
| DeepLabV3 | 8 MB | Image segmentation |
| FCRN-DepthPrediction | 127 MB | Depth estimation |

## Usage

```swift
let aiVision = AIVisionProcessor()

// Classify scene
let sceneResults = await aiVision.classifyScene(image)
print("Scene: \(sceneResults.topCategory)")

// Detect objects with bounding boxes
let objectResults = await aiVision.detectObjects(image)
for object in objectResults {
    print("\(object.label) at \(object.boundingBox)")
}

// Custom model inference
let customModel = try await aiVision.loadModel(named: "MyCustomModel")
let prediction = await aiVision.predict(image, using: customModel)
```

## Files

- `AIVisionProcessor.swift` - Main AI processing class
- `ModelManager.swift` - Core ML model loading and management
- `ResultsOverlay.swift` - SwiftUI view for visualizing results

## Use Cases for Glasses

### Navigation Assistance
- Detect obstacles
- Read signs
- Identify landmarks

### Shopping Helper
- Scan products
- Compare prices (via barcode)
- Find items

### Accessibility
- Describe scenes for visually impaired
- Read text aloud
- Identify people

### Work/Professional
- Scan business cards
- Document capture
- Meeting notes from whiteboards

## Limitations

- Processing happens on iPhone, not glasses
- Latency of 1-3 seconds for complex models
- Battery impact on phone
- Model size constraints (~200MB max recommended)
