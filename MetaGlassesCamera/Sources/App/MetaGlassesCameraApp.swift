/*
 * Meta Glasses Camera App
 * Based on Meta Wearables Device Access Toolkit Sample
 *
 * Main entry point for the app demonstrating the Meta Wearables DAT SDK.
 * This app shows how to connect to wearable devices (like Ray-Ban Meta smart glasses),
 * stream live video from their cameras, and capture photos.
 */

import Foundation
import MWDATCore
import SwiftUI

#if DEBUG
import MWDATMockDevice
#endif

@main
struct MetaGlassesCameraApp: App {
    #if DEBUG
    // Debug menu for simulating device connections during development
    @StateObject private var debugMenuViewModel = DebugMenuViewModel(mockDeviceKit: MockDeviceKit.shared)
    #endif
    private let wearables: WearablesInterface
    @StateObject private var wearablesViewModel: WearablesViewModel

    init() {
        do {
            try Wearables.configure()
        } catch {
            #if DEBUG
            NSLog("[MetaGlassesCamera] Failed to configure Wearables SDK: \(error)")
            #endif
        }
        let wearables = Wearables.shared
        self.wearables = wearables
        self._wearablesViewModel = StateObject(wrappedValue: WearablesViewModel(wearables: wearables))
    }

    var body: some Scene {
        WindowGroup {
            // Main app view with access to the shared Wearables SDK instance
            MainAppView(wearables: Wearables.shared, viewModel: wearablesViewModel)
                // Show error alerts for view model failures
                .alert("Error", isPresented: $wearablesViewModel.showError) {
                    Button("OK") {
                        wearablesViewModel.dismissError()
                    }
                } message: {
                    Text(wearablesViewModel.errorMessage)
                }
                #if DEBUG
                .sheet(isPresented: $debugMenuViewModel.showDebugMenu) {
                    MockDeviceKitView(viewModel: debugMenuViewModel.mockDeviceKitViewModel)
                }
                .overlay {
                    DebugMenuView(debugMenuViewModel: debugMenuViewModel)
                }
                #endif

            // Registration view handles the flow for connecting to the glasses via Meta AI
            RegistrationView(viewModel: wearablesViewModel)
        }
    }
}
