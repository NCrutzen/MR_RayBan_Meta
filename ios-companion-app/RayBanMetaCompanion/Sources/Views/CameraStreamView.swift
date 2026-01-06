import SwiftUI
import MWDATCore
import MWDATCamera

struct CameraStreamView: View {
    @EnvironmentObject var glassesManager: GlassesConnectionManager
    @Environment(\.dismiss) private var dismiss

    @State private var isStreaming = false
    @State private var currentFrame: UIImage?
    @State private var streamError: String?
    @State private var frameCount = 0
    @State private var frameListenerToken: (any AnyListenerToken)?

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Camera preview area
                cameraPreview
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Controls
                controlsBar
            }
        }
        .onDisappear {
            Task {
                await stopStream()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Camera Stream")
                    .font(.headline)
                    .foregroundStyle(.white)

                if glassesManager.isMockDeviceActive {
                    Text("Mock Device")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            // Frame counter
            Text("\(frameCount) frames")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(.ultraThinMaterial))
        }
        .padding()
    }

    // MARK: - Camera Preview

    private var cameraPreview: some View {
        ZStack {
            if let frame = currentFrame {
                Image(uiImage: frame)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isStreaming {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)

                    Text("Waiting for frames...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            } else if let error = streamError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)

                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("Tap Start to begin streaming")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    if !glassesManager.isConnected {
                        Text("Glasses not connected")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    // MARK: - Controls

    private var controlsBar: some View {
        HStack(spacing: 24) {
            // Capture photo button
            Button(action: capturePhoto) {
                VStack(spacing: 4) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    Text("Photo")
                        .font(.caption2)
                }
                .foregroundStyle(isStreaming ? .white : .white.opacity(0.4))
                .frame(width: 60)
            }
            .disabled(!isStreaming)

            // Main stream button
            Button(action: toggleStream) {
                ZStack {
                    Circle()
                        .fill(isStreaming ? .red : MoyneRoberts.accent)
                        .frame(width: 72, height: 72)

                    if isStreaming {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .offset(x: 2)
                    }
                }
            }
            .disabled(!glassesManager.isConnected)

            // Settings button
            Button(action: {}) {
                VStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                    Text("Settings")
                        .font(.caption2)
                }
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 60)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal)
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func toggleStream() {
        if isStreaming {
            Task {
                await stopStream()
            }
        } else {
            Task {
                await startStream()
            }
        }
    }

    private func startStream() async {
        streamError = nil
        isStreaming = true
        frameCount = 0

        print("[CameraStream] Starting stream...")

        guard let session = await glassesManager.startCameraStream() else {
            streamError = "Failed to start camera stream"
            isStreaming = false
            print("[CameraStream] Failed to get stream session")
            return
        }

        // Listen for video frames - keep token to prevent deallocation
        frameListenerToken = session.videoFramePublisher.listen { frame in
            Task { @MainActor in
                self.handleFrame(frame)
            }
        }

        print("[CameraStream] Stream started, listening for frames... (token retained: \(frameListenerToken != nil))")

        // Also listen for stream state changes
        _ = session.statePublisher.listen { state in
            Task { @MainActor in
                print("[CameraStream] Stream state from view: \(state)")
                if state == .stopped && self.isStreaming {
                    print("[CameraStream] Stream stopped unexpectedly!")
                    self.streamError = "Stream stopped - check video format (h265 may be required)"
                    self.isStreaming = false
                }
            }
        }
    }

    private func stopStream() async {
        guard isStreaming else {
            print("[CameraStream] Already stopped, skipping")
            return
        }
        print("[CameraStream] Stopping stream...")
        isStreaming = false
        frameListenerToken = nil
        await glassesManager.stopCameraStream()
        currentFrame = nil
    }

    private func handleFrame(_ frame: VideoFrame) {
        frameCount += 1

        if frameCount <= 5 || frameCount % 30 == 0 {
            print("[CameraStream] Frame #\(frameCount) received")
        }

        // Convert VideoFrame to UIImage using the SDK's built-in method
        if let image = frame.makeUIImage() {
            currentFrame = image
            if frameCount == 1 {
                print("[CameraStream] First frame converted to UIImage: \(image.size)")
            }
        } else if frameCount <= 5 {
            print("[CameraStream] Frame #\(frameCount) - makeUIImage() returned nil")
        }
    }

    private func capturePhoto() {
        guard isStreaming else { return }

        let success = glassesManager.capturePhoto()
        print("[CameraStream] Photo capture: \(success ? "success" : "failed")")

        // Visual feedback
        if success {
            // Could add a flash animation here
        }
    }
}

#Preview {
    CameraStreamView()
        .environmentObject(GlassesConnectionManager())
}
