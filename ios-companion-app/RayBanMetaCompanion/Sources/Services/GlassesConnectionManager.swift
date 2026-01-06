import Foundation
import Combine
import UIKit
import MWDATCore
import MWDATCamera
import MWDATMockDevice

/// Manages connection to Ray-Ban Meta glasses using the Meta Wearables Device Access Toolkit
@MainActor
class GlassesConnectionManager: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastActivityDate: Date?
    @Published var glassesModel: String = "Ray-Ban Meta"
    @Published var permissionStatus: String = "Not Requested"
    @Published var batteryLevel: Int?

    // MARK: - SDK Properties

    private var wearables: (any WearablesInterface)?
    private var currentDeviceId: DeviceIdentifier?
    private var streamSession: StreamSession?
    private var listenerTokens: [any AnyListenerToken] = []

    // MARK: - Mock Device Properties

    @Published var isMockDeviceActive = false
    private var mockDevice: MockRaybanMeta?
    private var mockCameraKit: MockCameraKit?

    enum ConnectionStatus: String {
        case disconnected = "Not Detected"
        case searching = "Searching..."
        case connecting = "Connecting..."
        case connected = "Connected"
        case permissionRequired = "Permission Required"
    }

    // MARK: - Initialization

    override init() {
        super.init()
        Task {
            await initializeSDK()
        }
    }

    // MARK: - SDK Initialization

    private func initializeSDK() async {
        connectionStatus = .searching

        // SDK is already configured in App init, just get the shared instance
        wearables = Wearables.shared

        // Listen for registration state changes
        setupRegistrationListener()

        // Listen for device changes
        setupDeviceListener()

        // Check if already registered
        if let wearables = wearables {
            let state = wearables.registrationState
            handleRegistrationState(state)
        }

        print("[GlassesManager] Meta Wearables SDK initialized")
    }

    // MARK: - Listeners

    private func setupRegistrationListener() {
        guard let wearables = wearables else { return }

        let token = wearables.addRegistrationStateListener { [weak self] state in
            Task { @MainActor in
                self?.handleRegistrationState(state)
            }
        }
        listenerTokens.append(token)
    }

    private func setupDeviceListener() {
        guard let wearables = wearables else { return }

        let token = wearables.addDevicesListener { [weak self] deviceIds in
            Task { @MainActor in
                self?.handleDevicesUpdate(deviceIds)
            }
        }
        listenerTokens.append(token)
    }

    private func handleRegistrationState(_ state: RegistrationState) {
        print("[GlassesManager] Registration state: \(state.description) (rawValue: \(state.rawValue))")

        switch state {
        case .registered:
            permissionStatus = "Registered with Meta AI"
            print("[GlassesManager] REGISTERED! Checking for devices...")
            // Check for devices
            if let devices = wearables?.devices, !devices.isEmpty {
                print("[GlassesManager] Found \(devices.count) device(s): \(devices)")
                handleDevicesUpdate(devices)
            } else {
                print("[GlassesManager] No devices found yet, waiting...")
                // Registered but no devices yet - keep checking
                connectionStatus = .searching
            }

        case .available:
            permissionStatus = "Tap Search to connect"
            // Always show disconnected so the Search button appears
            connectionStatus = .disconnected
            print("[GlassesManager] Set connectionStatus to .disconnected - Search button should be visible")

        case .registering:
            permissionStatus = "Authorizing with Meta AI..."
            connectionStatus = .connecting

        case .unavailable:
            permissionStatus = "Meta AI not available"
            connectionStatus = .disconnected

        @unknown default:
            break
        }
    }

    private func handleDevicesUpdate(_ deviceIds: [DeviceIdentifier]) {
        print("[GlassesManager] Devices: \(deviceIds)")

        // Don't let SDK device updates override mock device state
        if isMockDeviceActive && deviceIds.isEmpty {
            print("[GlassesManager] Ignoring empty device list - mock device is active")
            return
        }

        if let firstDeviceId = deviceIds.first {
            currentDeviceId = firstDeviceId

            // Get device info
            if let device = wearables?.deviceForIdentifier(firstDeviceId) {
                glassesModel = device.nameOrId()

                // Listen for link state
                let token = device.addLinkStateListener { [weak self] linkState in
                    Task { @MainActor in
                        self?.handleLinkState(linkState)
                    }
                }
                listenerTokens.append(token)

                // Check current link state
                handleLinkState(device.linkState)
            }

            // Check permissions
            Task {
                await checkPermissions()
            }
        } else {
            currentDeviceId = nil
            isConnected = false
            connectionStatus = .disconnected
        }
    }

    private func handleLinkState(_ state: LinkState) {
        print("[GlassesManager] Link state: \(state)")

        // Don't let SDK state changes override mock device state
        if isMockDeviceActive {
            print("[GlassesManager] Ignoring link state change - mock device is active")
            return
        }

        switch state {
        case .connected:
            isConnected = true
            connectionStatus = .connected
            lastActivityDate = Date()

        case .connecting:
            connectionStatus = .connecting

        case .disconnected:
            isConnected = false
            if connectionStatus != .searching {
                connectionStatus = .disconnected
            }

        @unknown default:
            break
        }
    }

    // MARK: - Permissions

    private func checkPermissions() async {
        guard let wearables = wearables else { return }

        do {
            let status = try await wearables.checkPermissionStatus(.camera)

            switch status {
            case .granted:
                permissionStatus = "Camera Granted"
            case .denied:
                permissionStatus = "Camera Denied"
                connectionStatus = .permissionRequired
            @unknown default:
                break
            }
        } catch {
            print("[GlassesManager] Permission check failed: \(error)")
        }
    }

    private func requestCameraPermission() async {
        guard let wearables = wearables else { return }

        do {
            let status = try await wearables.requestPermission(.camera)

            switch status {
            case .granted:
                permissionStatus = "Camera Granted"
                print("[GlassesManager] Camera permission granted")
            case .denied:
                permissionStatus = "Camera Denied"
                connectionStatus = .permissionRequired
            @unknown default:
                break
            }
        } catch {
            print("[GlassesManager] Permission request failed: \(error)")
        }
    }

    // MARK: - Public Methods

    /// Start searching for glasses / registration
    func startSearching() {
        print("[GlassesManager] startSearching() called!")
        connectionStatus = .searching

        guard let wearables = wearables else {
            print("[GlassesManager] startSearching: wearables is nil")
            connectionStatus = .disconnected
            return
        }

        let currentState = wearables.registrationState
        print("[GlassesManager] startSearching: current state = \(currentState.description) (rawValue: \(currentState.rawValue))")

        // If not registered, start registration
        if currentState != .registered {
            do {
                print("[GlassesManager] startSearching: calling startRegistration()...")
                try wearables.startRegistration()
                print("[GlassesManager] startSearching: startRegistration() succeeded - should open Meta AI app")
            } catch {
                print("[GlassesManager] startSearching: Registration failed with error: \(error)")
                connectionStatus = .disconnected
            }
        } else {
            // Already registered, check devices
            print("[GlassesManager] startSearching: already registered, checking devices...")
            handleDevicesUpdate(wearables.devices)
        }
    }

    /// Stop and disconnect
    func disconnect() {
        Task {
            await streamSession?.stop()
        }
        streamSession = nil
        isConnected = false
        connectionStatus = .disconnected
    }

    /// Manually refresh connection status
    func refresh() {
        if isConnected {
            lastActivityDate = Date()
        } else {
            startSearching()
        }
    }

    /// Handle URL callback from Meta AI app
    func handleURL(_ url: URL) async -> Bool {
        guard let wearables = wearables else { return false }

        do {
            return try await wearables.handleUrl(url)
        } catch {
            print("[GlassesManager] URL handling failed: \(error)")
            return false
        }
    }

    /// Open the Meta View app if installed
    func openMetaViewApp() {
        if let url = URL(string: "metaview://"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }

        if let appStoreURL = URL(string: "https://apps.apple.com/app/meta-view/id1613849498") {
            UIApplication.shared.open(appStoreURL)
        }
    }

    // MARK: - Camera Streaming

    /// Start camera streaming from glasses
    func startCameraStream() async -> StreamSession? {
        guard let wearables = wearables else {
            print("[GlassesManager] startCameraStream: wearables is nil")
            return nil
        }

        // For mock device or real device, we need a device ID
        // Mock device creates its own device that appears in wearables.devices
        if currentDeviceId == nil {
            // Try to get device from wearables
            if let firstDevice = wearables.devices.first {
                currentDeviceId = firstDevice
                print("[GlassesManager] startCameraStream: Using device \(firstDevice)")
            } else {
                print("[GlassesManager] startCameraStream: No device available")
                return nil
            }
        }

        let deviceSelector = AutoDeviceSelector(wearables: wearables)
        print("[GlassesManager] startCameraStream: Creating stream session...")

        let config = StreamSessionConfig(
            videoCodec: .raw,
            resolution: .high,
            frameRate: 30
        )

        streamSession = StreamSession(streamSessionConfig: config, deviceSelector: deviceSelector)

        // Listen for video frames
        let frameToken = streamSession?.videoFramePublisher.listen { [weak self] frame in
            Task { @MainActor in
                self?.handleVideoFrame(frame)
            }
        }
        if let token = frameToken {
            listenerTokens.append(token)
        }

        // Listen for state changes
        let stateToken = streamSession?.statePublisher.listen { [weak self] state in
            Task { @MainActor in
                self?.handleStreamState(state)
            }
        }
        if let token = stateToken {
            listenerTokens.append(token)
        }

        await streamSession?.start()

        return streamSession
    }

    /// Stop camera streaming
    func stopCameraStream() async {
        await streamSession?.stop()
        streamSession = nil
    }

    /// Capture a photo from glasses
    func capturePhoto(format: PhotoCaptureFormat = .jpeg) -> Bool {
        guard let session = streamSession else {
            return false
        }
        return session.capturePhoto(format: format)
    }

    // MARK: - Private Helpers

    private func handleVideoFrame(_ frame: VideoFrame) {
        lastActivityDate = Date()
        // Process video frame - can be used for preview or AI analysis
    }

    private func handleStreamState(_ state: StreamSessionState) {
        print("[GlassesManager] Stream state changed to: \(state)")

        // Log additional info for debugging
        switch state {
        case .streaming:
            print("[GlassesManager] Stream is now actively streaming frames")
        case .stopped:
            print("[GlassesManager] Stream has stopped")
        case .waitingForDevice:
            print("[GlassesManager] Stream waiting for device connection")
        case .stopping:
            print("[GlassesManager] Stream is stopping...")
        case .starting:
            print("[GlassesManager] Stream is starting...")
        case .paused:
            print("[GlassesManager] Stream is paused")
        @unknown default:
            print("[GlassesManager] Unknown stream state: \(state)")
        }
    }

    // MARK: - Mock Device Kit

    /// Pair a mock Ray-Ban Meta device for testing without physical glasses
    func pairMockDevice() {
        print("[GlassesManager] Pairing mock device...")

        // Pair mock device
        mockDevice = MockDeviceKit.shared.pairRaybanMeta()
        mockCameraKit = mockDevice?.getCameraKit()

        isMockDeviceActive = true
        glassesModel = "Ray-Ban Meta (Mock)"

        print("[GlassesManager] Mock device paired: \(mockDevice != nil)")
        print("[GlassesManager] Mock camera kit: \(mockCameraKit != nil)")

        // Auto-setup mock device for immediate use
        if let device = mockDevice {
            device.powerOn()
            device.unfold()
            device.don()
            print("[GlassesManager] Mock device auto-configured (power on, unfold, don)")
        }

        // Set connected state
        isConnected = true
        connectionStatus = .connected
        permissionStatus = "Mock Device Ready"
        lastActivityDate = Date()

        print("[GlassesManager] Mock device ready - isConnected: \(isConnected), status: \(connectionStatus.rawValue)")
    }

    /// Power on the mock device
    func mockPowerOn() {
        guard let device = mockDevice else {
            print("[GlassesManager] No mock device to power on")
            return
        }
        device.powerOn()
        connectionStatus = .connected
        isConnected = true
        lastActivityDate = Date()
        print("[GlassesManager] Mock device powered on")
    }

    /// Unfold mock device (required for streaming)
    func mockUnfold() {
        guard let device = mockDevice else {
            print("[GlassesManager] No mock device to unfold")
            return
        }
        device.unfold()
        print("[GlassesManager] Mock device unfolded - ready for streaming")
    }

    /// Don mock device (simulate wearing glasses)
    func mockDon() {
        guard let device = mockDevice else {
            print("[GlassesManager] No mock device to don")
            return
        }
        device.don()
        print("[GlassesManager] Mock device donned")
    }

    /// Set mock camera video feed from a file URL
    func setMockVideoFeed(fileURL: URL) async {
        guard let camera = mockCameraKit else {
            print("[GlassesManager] No mock camera kit available")
            return
        }
        await camera.setCameraFeed(fileURL: fileURL)
        print("[GlassesManager] Mock video feed set: \(fileURL)")
    }

    /// Set mock captured image from a file URL
    func setMockCapturedImage(fileURL: URL) async {
        guard let camera = mockCameraKit else {
            print("[GlassesManager] No mock camera kit available")
            return
        }
        await camera.setCapturedImage(fileURL: fileURL)
        print("[GlassesManager] Mock captured image set: \(fileURL)")
    }

    /// Unpair mock device
    func unpairMockDevice() {
        if let device = mockDevice {
            MockDeviceKit.shared.unpairDevice(device)
        }
        mockDevice = nil
        mockCameraKit = nil
        isMockDeviceActive = false
        isConnected = false
        connectionStatus = .disconnected
        glassesModel = "Ray-Ban Meta"
        permissionStatus = "Not Requested"
        print("[GlassesManager] Mock device unpaired")
    }
}

// MARK: - Errors

enum GlassesError: LocalizedError {
    case notConnected
    case noActiveStream
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Glasses are not connected"
        case .noActiveStream:
            return "No active camera stream"
        case .permissionDenied:
            return "Camera permission denied"
        }
    }
}
