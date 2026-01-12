/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// NonStreamView.swift
//
// Default screen to show getting started tips after app connection
// Initiates streaming and provides photo analysis option
//

import MWDATCore
import SwiftUI
import UIKit

struct NonStreamView: View {
  @ObservedObject var viewModel: StreamSessionViewModel
  @ObservedObject var wearablesVM: WearablesViewModel
  @State private var sheetHeight: CGFloat = 300

  // Photo analysis state
  @StateObject private var analysisService = FireHazardAnalysisService()
  @State private var showPhotoPicker = false
  @State private var showPhotoPreview = false
  @State private var showAnalysisResult = false
  @State private var selectedPhoto: UIImage?

  var body: some View {
    ZStack {
      Color.black.edgesIgnoringSafeArea(.all)

      VStack {
        HStack {
          Spacer()
          Menu {
            Button("Disconnect", role: .destructive) {
              wearablesVM.disconnectGlasses()
            }
            .disabled(wearablesVM.registrationState != .registered)
          } label: {
            Image(systemName: "gearshape")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .foregroundColor(.white)
              .frame(width: 24, height: 24)
          }
        }

        Spacer()

        VStack(spacing: 12) {
          Image(.cameraAccessIcon)
            .resizable()
            .renderingMode(.template)
            .foregroundColor(.white)
            .aspectRatio(contentMode: .fit)
            .frame(width: 100)

          Text("Fire Safety Inspection")
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.white)

          Text("Analyze photos for fire hazards using AI or stream from your glasses camera.")
            .font(.system(size: 15))
            .multilineTextAlignment(.center)
            .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)

        Spacer()

        // Action Buttons
        VStack(spacing: 12) {
          // Photo Library Button (Primary)
          Button(action: { showPhotoPicker = true }) {
            HStack {
              Image(systemName: "photo.on.rectangle")
              Text("Choose Photo from Library")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.mrSecondary)
            .cornerRadius(12)
          }

          // Divider
          HStack {
            Rectangle()
              .fill(Color.white.opacity(0.3))
              .frame(height: 1)
            Text("or")
              .font(.system(size: 14))
              .foregroundColor(.white.opacity(0.7))
              .padding(.horizontal, 12)
            Rectangle()
              .fill(Color.white.opacity(0.3))
              .frame(height: 1)
          }
          .padding(.vertical, 4)

          // Device status
          if !viewModel.hasActiveDevice {
            HStack(spacing: 8) {
              Image(systemName: "hourglass")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 16, height: 16)

              Text("Waiting for glasses connection...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            }
          }

          // Start Streaming Button
          CustomButton(
            title: "Start Streaming from Glasses",
            style: .primary,
            isDisabled: !viewModel.hasActiveDevice
          ) {
            Task {
              await viewModel.handleStartStreaming()
            }
          }
        }
      }
      .padding(.all, 24)

      // Loading overlay
      if analysisService.isAnalyzing {
        MRLoadingOverlay(message: "Analyzing for\nfire hazards...")
      }
    }
    .sheet(isPresented: Binding(
      get: { wearablesVM.showGettingStartedSheet || showPhotoPicker },
      set: { newValue in
        if !newValue {
          wearablesVM.showGettingStartedSheet = false
          showPhotoPicker = false
        }
      }
    )) {
      if showPhotoPicker {
        ImagePicker(selectedImage: $selectedPhoto, isPresented: $showPhotoPicker)
      } else {
        if #available(iOS 16.0, *) {
          GettingStartedSheetView(height: $sheetHeight)
            .presentationDetents([.height(sheetHeight)])
            .presentationDragIndicator(.visible)
        } else {
          GettingStartedSheetView(height: $sheetHeight)
        }
      }
    }
    // Photo Preview - using onChange to trigger after picker closes
    .onChange(of: selectedPhoto) { newPhoto in
      if newPhoto != nil && !showPhotoPicker {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          showPhotoPreview = true
        }
      }
    }
    // Photo Preview Sheet
    .fullScreenCover(isPresented: $showPhotoPreview) {
      PhotoPreviewWrapper(
        photo: selectedPhoto,
        onDismiss: {
          showPhotoPreview = false
          selectedPhoto = nil
        },
        onAnalyze: { image in
          showPhotoPreview = false
          Task {
            await analysisService.analyzePhoto(image)
            showAnalysisResult = true
          }
        }
      )
    }
    // Analysis Result Sheet
    .fullScreenCover(isPresented: $showAnalysisResult) {
      AnalysisResultWrapper(
        result: analysisService.analysisResult,
        onDismiss: {
          showAnalysisResult = false
          analysisService.clearResult()
        },
        onNewScan: {
          showAnalysisResult = false
          analysisService.clearResult()
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showPhotoPicker = true
          }
        }
      )
    }
  }

  // Helper function to show photo picker
  private func openPhotoPicker() {
    showPhotoPicker = true
  }
}

// MARK: - Wrapper Views to handle optional content

struct PhotoPreviewWrapper: View {
  let photo: UIImage?
  let onDismiss: () -> Void
  let onAnalyze: (UIImage) -> Void

  var body: some View {
    if let photo = photo {
      PhotoPreviewView(
        photo: photo,
        onDismiss: onDismiss,
        onAnalyze: onAnalyze
      )
    } else {
      Color.black
        .ignoresSafeArea()
        .onAppear {
          onDismiss()
        }
    }
  }
}

struct AnalysisResultWrapper: View {
  let result: AnalysisResult?
  let onDismiss: () -> Void
  let onNewScan: () -> Void

  var body: some View {
    if let result = result {
      AnalysisResultView(
        result: result,
        onDismiss: onDismiss,
        onNewScan: onNewScan
      )
    } else {
      Color.black
        .ignoresSafeArea()
        .onAppear {
          onDismiss()
        }
    }
  }
}

// MARK: - Simple Image Picker using UIImagePickerController

struct ImagePicker: UIViewControllerRepresentable {
  @Binding var selectedImage: UIImage?
  @Binding var isPresented: Bool

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .photoLibrary
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let parent: ImagePicker

    init(_ parent: ImagePicker) {
      self.parent = parent
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
      if let image = info[.originalImage] as? UIImage {
        parent.selectedImage = image
      }
      parent.isPresented = false
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.isPresented = false
    }
  }
}

struct GettingStartedSheetView: View {
  @Environment(\.dismiss) var dismiss
  @Binding var height: CGFloat

  var body: some View {
    VStack(spacing: 24) {
      Text("Getting started")
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(.primary)

      VStack(spacing: 12) {
        TipItemView(
          resource: .videoIcon,
          text: "First, Camera Access needs permission to use your glasses camera."
        )
        TipItemView(
          resource: .tapIcon,
          text: "Capture photos by tapping the camera button."
        )
        TipItemView(
          resource: .smartGlassesIcon,
          text: "The capture LED lets others know when you're capturing content or going live."
        )
      }
      .padding(.bottom, 16)

      CustomButton(
        title: "Continue",
        style: .primary,
        isDisabled: false
      ) {
        dismiss()
      }
    }
    .padding(.all, 24)
    .background(
      GeometryReader { geo -> Color in
        DispatchQueue.main.async {
          height = geo.size.height
        }
        return Color.clear
      }
    )
  }
}

struct TipItemView: View {
  let resource: ImageResource
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(resource)
        .resizable()
        .renderingMode(.template)
        .foregroundColor(.primary)
        .aspectRatio(contentMode: .fit)
        .frame(width: 24)
        .padding(.leading, 4)
        .padding(.top, 4)

      Text(text)
        .font(.system(size: 15))
        .foregroundColor(.primary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
