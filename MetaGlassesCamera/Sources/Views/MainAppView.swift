/*
 * MainAppView.swift
 *
 * Central navigation hub that displays different views based on DAT SDK registration and device states.
 * When unregistered, shows the registration flow. When registered, shows the streaming interface.
 */

import MWDATCore
import SwiftUI

struct MainAppView: View {
    let wearables: WearablesInterface
    @ObservedObject private var viewModel: WearablesViewModel

    init(wearables: WearablesInterface, viewModel: WearablesViewModel) {
        self.wearables = wearables
        self.viewModel = viewModel
    }

    var body: some View {
        if viewModel.registrationState == .registered || viewModel.hasMockDevice {
            StreamSessionView(wearables: wearables, wearablesVM: viewModel)
        } else {
            // User not registered - show registration/onboarding flow
            HomeScreenView(viewModel: viewModel)
        }
    }
}
