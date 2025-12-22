import Foundation
import CoreBluetooth
import Combine

/// Manages Bluetooth connection status with Ray-Ban Meta glasses
class GlassesConnectionManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var batteryLevel: Int?
    @Published var lastSeen: Date?

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?

    enum ConnectionStatus: String {
        case disconnected = "Disconnected"
        case scanning = "Scanning..."
        case connecting = "Connecting..."
        case connected = "Connected"
    }

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        connectionStatus = .scanning
        centralManager.scanForPeripherals(withServices: nil, options: nil)

        // Stop scanning after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.stopScanning()
        }
    }

    func stopScanning() {
        centralManager.stopScan()
        if connectionStatus == .scanning {
            connectionStatus = .disconnected
        }
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension GlassesConnectionManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        case .poweredOff:
            isConnected = false
            connectionStatus = .disconnected
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        // Check if this is a Ray-Ban Meta device
        guard let name = peripheral.name,
              name.contains("Ray-Ban") || name.contains("Meta") else {
            return
        }

        stopScanning()
        connectedPeripheral = peripheral
        connectionStatus = .connecting
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectionStatus = .connected
        lastSeen = Date()
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        connectionStatus = .disconnected
        connectedPeripheral = nil
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        connectionStatus = .disconnected
        connectedPeripheral = nil
    }
}

// MARK: - CBPeripheralDelegate

extension GlassesConnectionManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        // Handle discovered characteristics
        // Battery level, device info, etc.
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        // Handle characteristic value updates
    }
}
