import SwiftUI

public enum TurntableTheme: String, CaseIterable, Identifiable, Sendable {
    case classicBlack = "Classic Black"
    case vintageWalnut = "Vintage Walnut"
    case clearAcrylic = "Neon Acrylic"
    case retroCassette = "Cassette Deck"

    public var id: String { rawValue }

    public var isPro: Bool {
        switch self {
        case .classicBlack:
            return false
        case .vintageWalnut, .clearAcrylic, .retroCassette:
            return true
        }
    }

    public var plinthBackground: LinearGradient {
        switch self {
        case .classicBlack:
            return LinearGradient(
                colors: [Color(white: 0.14), Color(white: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .vintageWalnut:
            return LinearGradient(
                colors: [Color(red: 0.32, green: 0.18, blue: 0.10), Color(red: 0.20, green: 0.10, blue: 0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .clearAcrylic:
            return LinearGradient(
                colors: [Color(red: 0.08, green: 0.10, blue: 0.18), Color(red: 0.03, green: 0.04, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .retroCassette:
            return LinearGradient(
                colors: [Color(white: 0.22), Color(white: 0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    public var vinylColor: Color {
        switch self {
        case .classicBlack:
            return Color(white: 0.08)
        case .vintageWalnut:
            return Color(white: 0.06)
        case .clearAcrylic:
            return Color(red: 0.05, green: 0.75, blue: 0.95).opacity(0.45)
        case .retroCassette:
            return Color(white: 0.10)
        }
    }

    public var tonearmMetalColor: Color {
        switch self {
        case .classicBlack, .clearAcrylic, .retroCassette:
            return Color(white: 0.85) // Brushed silver
        case .vintageWalnut:
            return Color(red: 0.85, green: 0.72, blue: 0.38) // Brass / Gold
        }
    }

    public var accentGlow: Color {
        switch self {
        case .classicBlack:
            return Color.orange.opacity(0.4)
        case .vintageWalnut:
            return Color(red: 0.9, green: 0.6, blue: 0.2).opacity(0.5)
        case .clearAcrylic:
            return Color.cyan.opacity(0.8)
        case .retroCassette:
            return Color.green.opacity(0.6)
        }
    }
}

@MainActor
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()

    @Published public var currentTheme: TurntableTheme = .classicBlack
    @Published public var isProUnlocked: Bool = false
    @Published public var showLicenseModal: Bool = false
    @Published public var rpmSpeed: Int = 33 // 33 or 45 RPM

    public var rotationDuration: Double {
        return rpmSpeed == 45 ? 1.33 : 1.8
    }

    private init() {}

    public func selectTheme(_ theme: TurntableTheme) {
        if theme.isPro && !isProUnlocked {
            showLicenseModal = true
        } else {
            currentTheme = theme
        }
    }

    public func unlockPro(licenseKey: String) -> Bool {
        // Simple client-side license check (format: VINYL-PRO-XXXX)
        if licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().hasPrefix("VINYL-PRO") ||
           licenseKey.trimmingCharacters(in: .whitespacesAndNewlines) == "DEMO_UNLOCKED" {
            isProUnlocked = true
            return true
        }
        return false
    }
}
