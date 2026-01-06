import SwiftUI

// MARK: - Smeba / Moyne Roberts Corporate Theme

struct MoyneRoberts {
    // MARK: - Brand Colors (Smeba-inspired corporate palette)

    /// Primary brand color - Dark charcoal/navy
    static let primary = Color(hex: "32373c")

    /// Secondary color - Medium gray for text
    static let secondary = Color(hex: "555555")

    /// Light gray for backgrounds
    static let background = Color(hex: "F5F5F5")

    /// Accent color - Professional blue
    static let accent = Color(hex: "2563EB")

    /// Accent gradient colors
    static let accentLight = Color(hex: "3B82F6")
    static let accentDark = Color(hex: "1D4ED8")

    /// Status colors
    static let success = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")

    /// Card background
    static let cardBackground = Color.white

    /// Card border color
    static let cardBorder = Color(hex: "E5E7EB")

    // MARK: - Gradients

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(hex: "1A2744"),
            Color(hex: "32373c")
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let accentGradient = LinearGradient(
        colors: [accentLight, accentDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [
            Color.white,
            Color(hex: "F8F9FA")
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - App Info

    static let appName = "MR Smart Glasses"
    static let companyName = "Smeba Fire Safety"
    static let tagline = "Brandbeveiliging"
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Liquid Glass Card Modifier

struct LiquidGlassCard: ViewModifier {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    // Gradient overlay for depth
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(MoyneRoberts.cardGradient)
                    // Border highlight
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Liquid Glass Button Style

struct LiquidGlassButtonStyle: ButtonStyle {
    var isAccent: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    if isAccent {
                        Capsule()
                            .fill(MoyneRoberts.accentGradient)
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    }

                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Small Glass Button Style

struct SmallGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Icon Button Style

struct IconGlassButtonStyle: ButtonStyle {
    var size: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Accent Button Style (kept for compatibility)

struct MRAccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(MoyneRoberts.accentGradient)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 24, padding: CGFloat = 20) -> some View {
        modifier(LiquidGlassCard(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Static Corporate Background

struct AnimatedGradientBackground: View {
    var body: some View {
        MoyneRoberts.backgroundGradient
            .ignoresSafeArea()
    }
}

// MARK: - Clean Card Style

struct CleanCard: ViewModifier {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
    }
}

extension View {
    func cleanCard(cornerRadius: CGFloat = 16, padding: CGFloat = 20) -> some View {
        modifier(CleanCard(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let isActive: Bool
    var size: CGFloat = 12

    var body: some View {
        Circle()
            .fill(isActive ? MoyneRoberts.success : MoyneRoberts.warning)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: isActive ? MoyneRoberts.success.opacity(0.5) : MoyneRoberts.warning.opacity(0.5), radius: 4)
    }
}

// MARK: - Top Blur Overlay (for Dynamic Island)

struct TopBlurOverlay: View {
    var body: some View {
        VStack {
            LinearGradient(
                colors: [
                    Color(hex: "1A2744"),
                    Color(hex: "1A2744").opacity(0.8),
                    Color(hex: "1A2744").opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .blur(radius: 0.5)

            Spacer()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
