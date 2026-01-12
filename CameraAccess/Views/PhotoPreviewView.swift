/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// PhotoPreviewView.swift
//
// UI for previewing photos captured from Meta wearable devices via the DAT SDK.
// Includes option to analyze for fire safety hazards using Orq.ai.
//

import SwiftUI

struct PhotoPreviewView: View {
  let photo: UIImage
  let onDismiss: () -> Void
  let onAnalyze: ((UIImage) -> Void)?

  @State private var showShareSheet = false
  @State private var dragOffset = CGSize.zero

  init(photo: UIImage, onDismiss: @escaping () -> Void, onAnalyze: ((UIImage) -> Void)? = nil) {
    self.photo = photo
    self.onDismiss = onDismiss
    self.onAnalyze = onAnalyze
  }

  var body: some View {
    ZStack {
      // Semi-transparent background overlay
      Color.black.opacity(0.9)
        .ignoresSafeArea()

      VStack(spacing: 24) {
        // Header
        HStack {
          Button(action: { dismissWithAnimation() }) {
            Image(systemName: "xmark")
              .font(.system(size: 20, weight: .semibold))
              .foregroundColor(.white)
              .frame(width: 44, height: 44)
              .background(Color.white.opacity(0.2))
              .clipShape(Circle())
          }
          Spacer()
          Text("Photo Captured")
            .font(.headline)
            .foregroundColor(.white)
          Spacer()
          // Placeholder for symmetry
          Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)

        Spacer()

        // Photo display
        photoDisplayView

        Spacer()

        // Action buttons - Moyne Roberts styled
        VStack(spacing: 12) {
          // Analyze button (primary action)
          if onAnalyze != nil {
            Button(action: {
              onAnalyze?(photo)
            }) {
              HStack {
                Image(systemName: "flame.fill")
                Text("Analyze for Fire Safety")
              }
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
              .background(Color.mrPrimary)
              .cornerRadius(12)
            }
          }

          // Secondary actions
          HStack(spacing: 12) {
            Button(action: { showShareSheet = true }) {
              HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share")
              }
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(.mrPrimary)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 14)
              .background(Color.white)
              .cornerRadius(10)
            }

            Button(action: { dismissWithAnimation() }) {
              HStack {
                Image(systemName: "camera.fill")
                Text("New Photo")
              }
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 14)
              .background(Color.white.opacity(0.2))
              .cornerRadius(10)
            }
          }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
      }
      .offset(dragOffset)
      .animation(.spring(response: 0.6, dampingFraction: 0.8), value: dragOffset)
    }
    .sheet(isPresented: $showShareSheet) {
      ShareSheet(photo: photo)
    }
  }

  private var photoDisplayView: some View {
    GeometryReader { geometry in
      VStack {
        Spacer()
        Image(uiImage: photo)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: geometry.size.width - 32, maxHeight: geometry.size.height * 0.65)
          .cornerRadius(16)
          .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
          .gesture(
            DragGesture()
              .onChanged { value in
                dragOffset = value.translation
              }
              .onEnded { value in
                if abs(value.translation.height) > 100 {
                  dismissWithAnimation()
                } else {
                  withAnimation(.spring()) {
                    dragOffset = .zero
                  }
                }
              }
          )
        Spacer()
      }
      .frame(maxWidth: .infinity)
    }
  }

  private func dismissWithAnimation() {
    withAnimation(.easeInOut(duration: 0.3)) {
      dragOffset = CGSize(width: 0, height: UIScreen.main.bounds.height)
    }
    Task {
      try? await Task.sleep(nanoseconds: 300_000_000)
      onDismiss()
    }
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  let photo: UIImage

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let activityViewController = UIActivityViewController(
      activityItems: [photo],
      applicationActivities: nil
    )

    // Exclude certain activity types if needed
    activityViewController.excludedActivityTypes = [
      .assignToContact,
      .addToReadingList,
    ]

    return activityViewController
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    // No updates needed
  }
}
