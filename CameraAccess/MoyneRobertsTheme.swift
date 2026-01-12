/*
 * MoyneRobertsTheme.swift
 *
 * Moyne Roberts corporate branding and styling for the app.
 */

import SwiftUI

// MARK: - Moyne Roberts Colors

extension Color {
    // Primary brand colors
    static let mrPrimary = Color(red: 0/255, green: 82/255, blue: 147/255)      // Moyne Roberts Blue
    static let mrSecondary = Color(red: 220/255, green: 53/255, blue: 34/255)   // Moyne Roberts Red
    static let mrAccent = Color(red: 255/255, green: 152/255, blue: 0/255)      // Orange accent

    // UI Colors
    static let mrBackground = Color(red: 245/255, green: 247/255, blue: 250/255)
    static let mrCardBackground = Color.white
    static let mrTextPrimary = Color(red: 33/255, green: 37/255, blue: 41/255)
    static let mrTextSecondary = Color(red: 108/255, green: 117/255, blue: 125/255)

    // Risk level colors
    static let mrRiskLow = Color(red: 40/255, green: 167/255, blue: 69/255)      // Green
    static let mrRiskMedium = Color(red: 255/255, green: 193/255, blue: 7/255)   // Yellow
    static let mrRiskHigh = Color(red: 255/255, green: 152/255, blue: 0/255)     // Orange
    static let mrRiskCritical = Color(red: 220/255, green: 53/255, blue: 69/255) // Red
}

// MARK: - Moyne Roberts Button Styles

struct MRPrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isDisabled ? Color.gray : Color.mrPrimary)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct MRSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.mrPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.mrPrimary.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.mrPrimary, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct MRDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.mrSecondary)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Moyne Roberts Card Style

struct MRCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.mrCardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func mrCardStyle() -> some View {
        modifier(MRCardStyle())
    }
}

// MARK: - Moyne Roberts Header

struct MRHeaderView: View {
    let title: String
    let subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.mrTextPrimary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.mrTextSecondary)
            }
        }
    }
}

// MARK: - Risk Level Badge

struct RiskLevelBadge: View {
    let level: String

    var backgroundColor: Color {
        switch level.lowercased() {
        case "low": return .mrRiskLow
        case "medium": return .mrRiskMedium
        case "high": return .mrRiskHigh
        case "critical": return .mrRiskCritical
        default: return .mrTextSecondary
        }
    }

    var body: some View {
        Text(level.uppercased())
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .cornerRadius(8)
    }
}

// MARK: - Loading Overlay

struct MRLoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(Color.mrPrimary.opacity(0.9))
            .cornerRadius(16)
        }
    }
}
