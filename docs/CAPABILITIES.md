# Ray-Ban Meta Wayfarer Gen 2 - Capabilities Reference

## Hardware Capabilities

### Camera System
- **Resolution**: 12MP ultra-wide camera
- **Field of View**: ~120 degrees
- **Photo Formats**: JPEG, HEIC
- **Video Recording**:
  - 1080p @ 30fps (up to 60 seconds per clip)
  - 720p @ 30fps
- **Capture LED**: White LED indicates active recording (privacy indicator)

### Audio System
- **Microphones**: 5-microphone array for:
  - Voice commands
  - Audio recording
  - Noise cancellation during calls
- **Speakers**: Open-ear directional speakers
  - Personal audio (minimal sound leak)
  - Touch volume controls on temples

### Connectivity
- **Bluetooth**: 5.2 for iPhone pairing
- **WiFi**: For direct media transfer
- **Supported Devices**: iOS 14.4+ / Android 10+

### Physical Controls
| Control | Action |
|---------|--------|
| Capture button (right temple) | Single press: Photo / Long press: Video |
| Touch area (right temple) | Swipe for volume, tap for playback |
| Power button | On/off, pairing mode |

## Software Capabilities

### Meta AI Integration
- **Wake Word**: "Hey Meta"
- **Capabilities**:
  - Voice queries and Q&A
  - Object/scene identification (Look and Ask)
  - Real-time translation (select languages)
  - Smart replies for messages
  - Hands-free calling

### Voice Commands
```
"Hey Meta, take a photo"
"Hey Meta, start recording"
"Hey Meta, what am I looking at?"
"Hey Meta, call [contact name]"
"Hey Meta, send a message to [contact]"
"Hey Meta, read my messages"
"Hey Meta, what time is it?"
"Hey Meta, set a timer for [X] minutes"
"Hey Meta, play music"
"Hey Meta, pause/skip/previous"
```

### Live Streaming
- **Platforms**: Facebook Live, Instagram Live
- **Duration**: Up to 30 minutes per stream
- **Setup**: Requires Facebook/Instagram app on paired phone
- **Quality**: 720p streaming

### Messaging Integration
- **WhatsApp**: Hands-free messaging
- **Messenger**: Send and receive messages
- **SMS**: Read incoming messages (iOS)

## iPhone 14 Pro Specific Features

### ProMotion Display Sync
The iPhone 14 Pro's 120Hz display provides smooth video preview in the Meta View app.

### Camera Integration
- Captured media syncs to iPhone's photo library
- Supports iPhone's native editing tools
- HEIC format compatible with iPhone's storage optimization

### Shortcuts Integration
Create iOS Shortcuts that trigger based on:
- Media captured from glasses
- Time-based automation for glasses features
- Location-based triggers

## Integration Points for Development

### Meta View App
The official companion app provides:
- Glasses pairing and setup
- Firmware updates
- Media gallery and sync
- AI features configuration
- Live streaming controls

### Bluetooth Communication
- Glasses appear as Bluetooth audio device
- Media sync uses WiFi direct
- Control commands via Bluetooth LE

### Photo/Video Access
Captured media is accessible via:
1. Meta View app gallery
2. iPhone Photos app (after sync)
3. iOS Files app (limited)

### Webhook/API Limitations
> **Note**: As of 2024, Meta does not provide a public SDK for Ray-Ban Meta glasses.
> Custom integrations must work through:
> - iOS Shortcuts and automation
> - Photo library access on iPhone
> - Companion apps that monitor synced media

## Battery and Performance

| Activity | Battery Life |
|----------|--------------|
| Standby | ~36 hours |
| Music playback | ~4 hours |
| Voice calls | ~4 hours |
| Video recording | ~50-60 minutes total |
| Live streaming | ~30 minutes |

## Charging
- Charging case provides ~8 full charges
- Glasses: ~22 minutes for 50% charge
- Case: USB-C charging

## Privacy Features
- Capture LED always on during recording
- Voice activation can be disabled
- Guest mode for temporary users
- Remote wipe capability
