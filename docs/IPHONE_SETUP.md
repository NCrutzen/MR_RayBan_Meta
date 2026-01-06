# iPhone 14 Pro Setup Guide

## Prerequisites Checklist

- [ ] Ray-Ban Meta Wayfarer Gen 2 glasses
- [ ] iPhone 14 Pro with iOS 16.0 or later
- [ ] Meta View app installed from App Store
- [ ] Meta (Facebook) account
- [ ] Bluetooth enabled on iPhone
- [ ] WiFi network available

## Step 1: Download Required Apps

### Meta View App (Required)
1. Open App Store on iPhone 14 Pro
2. Search for "Meta View"
3. Download and install the app
4. Sign in with your Meta (Facebook) account

### Optional Apps
- **WhatsApp**: For hands-free messaging
- **Facebook**: For live streaming to Facebook Live
- **Instagram**: For live streaming to Instagram Live

## Step 2: Initial Glasses Setup

### Power On
1. Remove glasses from charging case
2. Press and hold the power button (inside right temple) for 3 seconds
3. You'll hear "Glasses on" confirmation

### Enter Pairing Mode
1. If first time setup: Glasses enter pairing mode automatically
2. If re-pairing: Hold power button for 8 seconds until you hear "Ready to pair"

## Step 3: Pair with iPhone 14 Pro

### In Meta View App
1. Open Meta View app
2. Tap "Set up new glasses" or the "+" icon
3. Select "Ray-Ban Meta" from device list
4. Follow on-screen instructions

### Bluetooth Pairing
1. When prompted, allow Bluetooth pairing
2. Confirm the pairing code matches on both devices
3. Tap "Pair" on iPhone

### Permissions Setup
Grant the following permissions when prompted:
- **Bluetooth**: Required for glasses communication
- **Photos**: To save captured media
- **Microphone**: For voice features
- **Notifications**: For alerts and messages

## Step 4: Configure Meta AI

### Enable Voice Assistant
1. In Meta View app, go to Settings > Voice Assistant
2. Enable "Hey Meta" wake word
3. Train voice recognition (optional but recommended)

### Configure AI Features
1. Settings > Meta AI
2. Enable features you want:
   - Look and Ask (visual queries)
   - Smart Replies
   - Translations

## Step 5: iPhone 14 Pro Optimizations

### Camera Roll Sync
1. Settings > Media > Photo Sync
2. Enable "Auto-sync to iPhone"
3. Choose sync preference:
   - WiFi only (recommended)
   - WiFi + Cellular

### Notifications
1. Settings > Notifications
2. Enable notifications you want read aloud:
   - Messages
   - Calls
   - Calendar

### Audio Settings
1. Settings > Audio
2. Adjust speaker volume
3. Configure touch controls

## Step 6: Live Streaming Setup (Optional)

### Facebook Live
1. Open Facebook app and log in
2. In Meta View: Settings > Live Streaming
3. Connect Facebook account
4. Test with: "Hey Meta, go live on Facebook"

### Instagram Live
1. Open Instagram app and log in
2. In Meta View: Settings > Live Streaming
3. Connect Instagram account
4. Test with: "Hey Meta, go live on Instagram"

## Step 7: Test Your Setup

### Quick Tests
1. **Photo capture**: Press capture button once
2. **Video recording**: Press and hold capture button
3. **Voice command**: Say "Hey Meta, what time is it?"
4. **Media sync**: Check iPhone Photos app for synced media

## Troubleshooting

### Glasses Won't Pair
1. Ensure glasses are charged (check case LEDs)
2. Restart iPhone Bluetooth: Settings > Bluetooth > Toggle off/on
3. Reset glasses: Hold power button for 15 seconds
4. Try pairing again

### Media Not Syncing
1. Ensure WiFi is connected on iPhone
2. Open Meta View app (sync requires app in foreground initially)
3. Check: Settings > Media > Sync Settings
4. Force sync: Pull down in Media gallery

### Voice Commands Not Working
1. Check microphone permissions
2. Ensure "Hey Meta" is enabled
3. Speak clearly, facing forward
4. Reduce background noise

### Poor Audio Quality
1. Clean speaker openings on temples
2. Adjust fit (speakers should align with ears)
3. Check volume: Swipe up on right temple

## Development Setup

### Xcode Configuration
For developing companion apps:
1. Install Xcode 15+ from Mac App Store
2. Open `ios-companion-app/RayBanMetaCompanion.xcodeproj`
3. Set your Apple Developer Team
4. Select iPhone 14 Pro as run target

### Enabling Developer Mode
1. iPhone Settings > Privacy & Security > Developer Mode
2. Enable Developer Mode
3. Restart iPhone when prompted

### Simulator Limitations
> **Note**: Glasses features require physical hardware.
> Use simulator only for UI development.

## Best Practices

### Battery Optimization
- Keep glasses in case when not in use
- Charge case regularly via USB-C
- Disable WiFi sync when not needed

### Privacy
- Remember the capture LED indicates active recording
- Use Guest Mode when lending glasses
- Review captured media before sharing

### Daily Workflow
1. Morning: Check glasses and case charge
2. Pair when needed (should auto-connect)
3. End of day: Place in charging case
