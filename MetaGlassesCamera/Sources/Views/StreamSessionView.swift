/*
 * StreamSessionView.swift
 *
 * Container view that manages the streaming session state and switches between
 * the pre-streaming setup view and the active streaming view.
 */

import MWDATCore
import SwiftUI

struct StreamSessionView: View {
    let wearables: WearablesInterface
    @ObservedObject private var wearablesViewModel: WearablesViewModel
    @StateObject private var viewModel: StreamSessionViewModel

    init(wearables: WearablesInterface, wearablesVM: WearablesViewModel) {
        self.wearables = wearables
        self.wearablesViewModel = wearablesVM
        self._viewModel = StateObject(wrappedValue: StreamSessionViewModel(wearables: wearables))
    }

    var body: some View {
        ZStack {
            if viewModel.isStreaming {
                // Full-screen video view with streaming controls
                StreamView(viewModel: viewModel, wearablesVM: wearablesViewModel)
            } else {
                // Pre-streaming setup view with permissions and start button
                NonStreamView(viewModel: viewModel, wearablesVM: wearablesViewModel)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
