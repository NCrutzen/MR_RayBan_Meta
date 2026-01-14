/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// StreamView.swift
//
// Main UI for video streaming from Meta wearable devices using the DAT SDK.
// This view demonstrates the complete streaming API: video streaming with real-time display, photo capture,
// fire safety analysis, and error handling.
//

import MWDATCore
import SwiftUI

struct StreamView: View {
  @ObservedObject var viewModel: StreamSessionViewModel
  @ObservedObject var wearablesVM: WearablesViewModel

  var body: some View {
    ZStack {
      // Black background for letterboxing/pillarboxing
      Color.black
        .edgesIgnoringSafeArea(.all)

      // Video backdrop
      if let videoFrame = viewModel.currentVideoFrame, viewModel.hasReceivedFirstFrame {
        GeometryReader { geometry in
          Image(uiImage: videoFrame)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .edgesIgnoringSafeArea(.all)
      } else {
        ProgressView()
          .scaleEffect(1.5)
          .foregroundColor(.white)
      }

      // Bottom controls layer
      VStack {
        // Moyne Roberts branding header
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text("MOYNE ROBERTS")
              .font(.system(size: 12, weight: .bold))
              .foregroundColor(.white.opacity(0.8))
            Text("Brandveiligheid Inspectie")
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(.white)
          }
          Spacer()
          // Recording indicator
          if viewModel.streamingStatus == .streaming {
            HStack(spacing: 6) {
              Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
              Text("LIVE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.5))
            .cornerRadius(8)
          }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)

        Spacer()

        // Timer display
        if viewModel.activeTimeLimit.isTimeLimited && viewModel.remainingTime > 0 {
          Text("Stream stopt over \(viewModel.remainingTime.formattedCountdown)")
            .font(.system(size: 15))
            .foregroundColor(.white)
            .padding(.bottom, 8)
        }

        ControlsView(viewModel: viewModel)
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 24)

      // Loading overlay during analysis
      if viewModel.isAnalyzing {
        MRLoadingOverlay(message: "Foto wordt geanalyseerd\nop brandveiligheid...")
      }
    }
    .onDisappear {
      Task {
        if viewModel.streamingStatus != .stopped {
          await viewModel.stopSession()
        }
      }
    }
    // Show captured photos from DAT SDK in a preview sheet with analyze option
    .sheet(isPresented: $viewModel.showPhotoPreview) {
      if let photo = viewModel.capturedPhoto {
        PhotoPreviewView(
          photo: photo,
          onDismiss: {
            viewModel.dismissPhotoPreview()
          },
          onAnalyze: { image in
            viewModel.analyzePhoto(image)
          }
        )
      }
    }
    // Show analysis results
    .fullScreenCover(isPresented: $viewModel.showAnalysisResult) {
      if let result = viewModel.analysisResult {
        AnalysisResultView(
          result: result,
          onDismiss: {
            viewModel.dismissAnalysisResult()
          },
          onNewScan: {
            viewModel.dismissAnalysisResult()
          }
        )
      }
    }
  }
}

// Extracted controls for clarity - Moyne Roberts styled
struct ControlsView: View {
  @ObservedObject var viewModel: StreamSessionViewModel

  var body: some View {
    // Controls row
    HStack(spacing: 12) {
      // Stop button
      Button(action: {
        Task {
          await viewModel.stopSession()
        }
      }) {
        HStack {
          Image(systemName: "stop.fill")
          Text("Stop")
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.mrSecondary)
        .cornerRadius(25)
      }

      Spacer()

      // Timer button
      CircleButton(
        icon: "timer",
        text: viewModel.activeTimeLimit != .noLimit ? viewModel.activeTimeLimit.displayText : nil
      ) {
        let nextTimeLimit = viewModel.activeTimeLimit.next
        viewModel.setTimeLimit(nextTimeLimit)
      }

      // Photo/Analyze button - larger and more prominent
      Button(action: {
        viewModel.capturePhoto()
      }) {
        ZStack {
          Circle()
            .fill(Color.mrPrimary)
            .frame(width: 72, height: 72)
          Circle()
            .stroke(Color.white, lineWidth: 3)
            .frame(width: 72, height: 72)
          VStack(spacing: 2) {
            Image(systemName: "camera.fill")
              .font(.system(size: 24))
            Text("Foto")
              .font(.system(size: 10, weight: .medium))
          }
          .foregroundColor(.white)
        }
      }
    }
  }
}
