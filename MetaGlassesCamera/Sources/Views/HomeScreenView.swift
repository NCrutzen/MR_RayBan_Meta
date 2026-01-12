/*
 * HomeScreenView.swift
 *
 * Welcome screen that guides users through the DAT SDK registration process.
 * This view is displayed when the app is not yet registered.
 */

import MWDATCore
import SwiftUI

struct HomeScreenView: View {
    @ObservedObject var viewModel: WearablesViewModel

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)

            VStack(spacing: 12) {
                Spacer()

                Image(systemName: "camera.viewfinder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120)
                    .foregroundColor(.appPrimary)

                VStack(spacing: 12) {
                    HomeTipItemView(
                        icon: "eyeglasses",
                        title: "Video Capture",
                        text: "Record videos directly from your glasses, from your point of view."
                    )
                    HomeTipItemView(
                        icon: "speaker.wave.2",
                        title: "Open-Ear Audio",
                        text: "Hear notifications while keeping your ears open to the world around you."
                    )
                    HomeTipItemView(
                        icon: "figure.walk",
                        title: "Enjoy On-the-Go",
                        text: "Stay hands-free while you move through your day. Move freely, stay connected."
                    )
                }

                Spacer()

                VStack(spacing: 16) {
                    // Developer Mode reminder
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Developer Mode Required")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                        Text("In Meta AI app: Settings → App Info → Tap version 5x to enable Developer Mode")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)

                    Text("You'll be redirected to the Meta AI app to confirm your connection.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)

                    CustomButton(
                        title: viewModel.registrationState == .registering ? "Connecting..." : "Connect my glasses",
                        style: .primary,
                        isDisabled: viewModel.registrationState == .registering
                    ) {
                        viewModel.connectGlasses()
                    }

                    // Troubleshooting button
                    Button(action: {
                        viewModel.showTroubleshooting = true
                    }) {
                        Text("Connection not working?")
                            .font(.system(size: 14))
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            .padding(.all, 24)
        }
        .sheet(isPresented: $viewModel.showTroubleshooting) {
            TroubleshootingView()
        }
    }
}

struct TroubleshootingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Step 1
                    TroubleshootingStepView(
                        step: 1,
                        title: "Check Glasses Firmware",
                        instructions: [
                            "Open the Meta AI app",
                            "Go to Devices tab (glasses icon)",
                            "Select your glasses",
                            "Tap Settings (gear icon)",
                            "Go to General → About → Version",
                            "You need version 20.0 or higher"
                        ]
                    )

                    // Step 2
                    TroubleshootingStepView(
                        step: 2,
                        title: "Enable Developer Mode",
                        instructions: [
                            "In Meta AI app, go to Settings",
                            "Tap on App Info",
                            "Tap the version number 5 times quickly",
                            "A Developer Mode toggle will appear",
                            "Turn ON Developer Mode",
                            "Tap Enable to confirm"
                        ]
                    )

                    // Step 3
                    TroubleshootingStepView(
                        step: 3,
                        title: "Ensure Glasses Are Connected",
                        instructions: [
                            "Make sure your glasses are powered on",
                            "Check that Bluetooth is enabled on your iPhone",
                            "Verify glasses are connected in Meta AI app",
                            "If not connected, pair them first via Meta AI app"
                        ]
                    )

                    // Step 4
                    TroubleshootingStepView(
                        step: 4,
                        title: "Try Again",
                        instructions: [
                            "Close and reopen this app",
                            "Make sure Meta AI app is running in background",
                            "Tap 'Connect my glasses' again",
                            "You should now see the permission prompt in Meta AI"
                        ]
                    )

                    // Additional help
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Still not working?")
                            .font(.headline)
                        Text("Make sure you have the latest version of the Meta AI app installed. The Device Access Toolkit requires Meta AI app to be up to date.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Troubleshooting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TroubleshootingStepView: View {
    let step: Int
    let title: String
    let instructions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 28, height: 28)
                    Text("\(step)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                Text(title)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(instruction)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.leading, 36)
        }
    }
}

struct HomeTipItemView: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.black)
                .frame(width: 24, height: 24)
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
