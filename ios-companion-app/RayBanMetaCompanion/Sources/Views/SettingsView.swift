import SwiftUI

struct SettingsView: View {
    @AppStorage("autoSync") private var autoSync = true
    @AppStorage("processNewPhotos") private var processNewPhotos = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("debugMode") private var debugMode = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Sync Settings") {
                    Toggle("Auto-sync Media", isOn: $autoSync)
                    Toggle("Process New Photos", isOn: $processNewPhotos)

                    NavigationLink("Sync Frequency") {
                        SyncFrequencyView()
                    }
                }

                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)

                    NavigationLink("Notification Types") {
                        NotificationTypesView()
                    }
                }

                Section("AI Processing") {
                    NavigationLink("Vision Settings") {
                        VisionSettingsView()
                    }

                    NavigationLink("ML Models") {
                        MLModelsView()
                    }
                }

                Section("Developer") {
                    Toggle("Debug Mode", isOn: $debugMode)

                    NavigationLink("Connection Logs") {
                        ConnectionLogsView()
                    }

                    NavigationLink("API Status") {
                        APIStatusView()
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Device")
                        Spacer()
                        Text("iPhone 14 Pro")
                            .foregroundStyle(.secondary)
                    }

                    Link("Ray-Ban Meta Support", destination: URL(string: "https://www.ray-ban.com/meta")!)

                    Link("Meta View App", destination: URL(string: "https://apps.apple.com/app/meta-view/id1613849498")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SyncFrequencyView: View {
    @AppStorage("syncFrequency") private var syncFrequency = "auto"

    var body: some View {
        Form {
            Picker("Sync Frequency", selection: $syncFrequency) {
                Text("Automatic").tag("auto")
                Text("Every 5 minutes").tag("5min")
                Text("Every 15 minutes").tag("15min")
                Text("Manual only").tag("manual")
            }
            .pickerStyle(.inline)
        }
        .navigationTitle("Sync Frequency")
    }
}

struct NotificationTypesView: View {
    @AppStorage("notifyNewMedia") private var notifyNewMedia = true
    @AppStorage("notifyConnection") private var notifyConnection = true
    @AppStorage("notifyProcessing") private var notifyProcessing = false

    var body: some View {
        Form {
            Toggle("New Media Synced", isOn: $notifyNewMedia)
            Toggle("Connection Status", isOn: $notifyConnection)
            Toggle("Processing Complete", isOn: $notifyProcessing)
        }
        .navigationTitle("Notification Types")
    }
}

struct VisionSettingsView: View {
    @AppStorage("enableOCR") private var enableOCR = true
    @AppStorage("enableFaceDetection") private var enableFaceDetection = true
    @AppStorage("enableObjectDetection") private var enableObjectDetection = true

    var body: some View {
        Form {
            Section("Detection Features") {
                Toggle("Text Recognition (OCR)", isOn: $enableOCR)
                Toggle("Face Detection", isOn: $enableFaceDetection)
                Toggle("Object Detection", isOn: $enableObjectDetection)
            }

            Section("Performance") {
                Picker("Processing Quality", selection: .constant("balanced")) {
                    Text("Fast").tag("fast")
                    Text("Balanced").tag("balanced")
                    Text("Accurate").tag("accurate")
                }
            }
        }
        .navigationTitle("Vision Settings")
    }
}

struct MLModelsView: View {
    var body: some View {
        Form {
            Section("Installed Models") {
                HStack {
                    Text("MobileNetV2")
                    Spacer()
                    Text("25 MB")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("YOLO Object Detection")
                    Spacer()
                    Text("62 MB")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Available") {
                HStack {
                    Text("DeepLabV3 Segmentation")
                    Spacer()
                    Button("Download") { }
                        .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("ML Models")
    }
}

struct ConnectionLogsView: View {
    var body: some View {
        List {
            Text("[12:34:56] Bluetooth scan started")
            Text("[12:34:58] Device found: Ray-Ban Meta")
            Text("[12:35:01] Connection established")
            Text("[12:35:02] Services discovered: 3")
        }
        .font(.system(.caption, design: .monospaced))
        .navigationTitle("Connection Logs")
    }
}

struct APIStatusView: View {
    var body: some View {
        Form {
            Section("Service Status") {
                HStack {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("Bluetooth")
                    Spacer()
                    Text("Connected")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("Photos Access")
                    Spacer()
                    Text("Authorized")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Circle().fill(.yellow).frame(width: 8, height: 8)
                    Text("Background Refresh")
                    Spacer()
                    Text("Limited")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("API Status")
    }
}

#Preview {
    SettingsView()
}
