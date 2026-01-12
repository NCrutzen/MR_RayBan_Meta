/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// HomeScreenView.swift
//
// Welcome screen that guides users through the DAT SDK registration process.
// This view is displayed when the app is not yet registered.
// Includes option to analyze photos from library for fire safety.
//

import MWDATCore
import SwiftUI

struct HomeScreenView: View {
  @ObservedObject var viewModel: WearablesViewModel

  // Photo analysis state
  @StateObject private var analysisService = FireHazardAnalysisService()
  @State private var showPhotoPicker = false
  @State private var showPhotoPreview = false
  @State private var showAnalysisResult = false
  @State private var selectedPhoto: UIImage?

  var body: some View {
    ZStack {
      Color.mrBackground.edgesIgnoringSafeArea(.all)

      VStack(spacing: 16) {
        // Moyne Roberts Header
        VStack(spacing: 8) {
          Text("Moyne Roberts")
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.mrPrimary)
          Text("Fire Safety Inspection")
            .font(.system(size: 16))
            .foregroundColor(.mrTextSecondary)
        }
        .padding(.top, 20)

        Spacer()

        // App Icon
        Image(.cameraAccessIcon)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 100)

        // Feature tips
        VStack(spacing: 12) {
          HomeTipItemView(
            resource: .smartGlassesIcon,
            title: "Smart Glasses",
            text: "Take photos directly from your Ray-Ban Meta glasses."
          )
          HomeTipItemView(
            resource: .walkingIcon,
            title: "Hands-free Inspection",
            text: "Walk around and capture fire safety hazards."
          )
        }

        Spacer()

        // Action Buttons
        VStack(spacing: 16) {
          // Photo Library Button
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

          // Divider with text
          HStack {
            Rectangle()
              .fill(Color.mrTextSecondary.opacity(0.3))
              .frame(height: 1)
            Text("or")
              .font(.system(size: 14))
              .foregroundColor(.mrTextSecondary)
              .padding(.horizontal, 12)
            Rectangle()
              .fill(Color.mrTextSecondary.opacity(0.3))
              .frame(height: 1)
          }
          .padding(.vertical, 4)

          // Connect Glasses Button
          VStack(spacing: 8) {
            Text("Connect your Meta glasses for live capture")
              .font(.system(size: 14))
              .foregroundColor(.mrTextSecondary)
              .multilineTextAlignment(.center)

            CustomButton(
              title: viewModel.registrationState == .registering ? "Connecting..." : "Connect Meta Glasses",
              style: .primary,
              isDisabled: viewModel.registrationState == .registering
            ) {
              viewModel.connectGlasses()
            }
          }
        }
        .padding(.bottom, 8)
      }
      .padding(.all, 24)

      // Loading overlay
      if analysisService.isAnalyzing {
        MRLoadingOverlay(message: "Analyzing for\nfire hazards...")
      }
    }
    // Photo Picker Sheet
    .sheet(isPresented: $showPhotoPicker, onDismiss: {
      // Show preview after picker dismissed if we have a photo
      if selectedPhoto != nil {
        showPhotoPreview = true
      }
    }) {
      HomeImagePicker(selectedImage: $selectedPhoto, isPresented: $showPhotoPicker)
    }
    // Photo Preview Sheet
    .fullScreenCover(isPresented: $showPhotoPreview) {
      if let photo = selectedPhoto {
        PhotoPreviewView(
          photo: photo,
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
    }
    // Analysis Result Sheet
    .fullScreenCover(isPresented: $showAnalysisResult) {
      if let result = analysisService.analysisResult {
        AnalysisResultView(
          result: result,
          onDismiss: {
            showAnalysisResult = false
            analysisService.clearResult()
          },
          onNewScan: {
            showAnalysisResult = false
            analysisService.clearResult()
            showPhotoPicker = true
          }
        )
      }
    }
  }
}

// MARK: - Simple Image Picker using UIImagePickerController

import UIKit

struct HomeImagePicker: UIViewControllerRepresentable {
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
    let parent: HomeImagePicker

    init(_ parent: HomeImagePicker) {
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

struct HomeTipItemView: View {
  let resource: ImageResource
  let title: String
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(resource)
        .resizable()
        .renderingMode(.template)
        .foregroundColor(.black)
        .aspectRatio(contentMode: .fit)
        .frame(width: 24)
        .padding(.leading, 4)
        .padding(.top, 4)

      VStack(alignment: .leading, spacing: 6) {
        Text(title)
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(.black)

        Text(text)
          .font(.system(size: 15))
          .foregroundColor(.gray)
      }
      Spacer()
    }
  }
}
