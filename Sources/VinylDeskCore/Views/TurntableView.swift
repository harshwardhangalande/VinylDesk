import SwiftUI

@MainActor
public final class TurntableViewState: ObservableObject {
    @Published public var licenseKeyInput: String = ""
    @Published public var licenseErrorMessage: String = ""
    public init() {}
}

public struct TurntableView: View {
    @StateObject private var coordinator = MusicCoordinator.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var viewState = TurntableViewState()

    public init() {}

    public var body: some View {
        ZStack {
            // Main Turntable Plinth (Chassis)
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentTheme.plinthBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.65), radius: 20, x: 0, y: 10)

            VStack(spacing: 8) {
                // Top Section: Platter + Tonearm + VU Meters
                HStack(alignment: .top, spacing: 14) {
                    // Left: Rotating Vinyl Platter
                    VinylPlatterView(coordinator: coordinator, themeManager: themeManager, size: 250)
                        .padding(.leading, 12)
                        .padding(.top, 12)

                    // Right Column: Tonearm & VU Meters
                    VStack(spacing: 12) {
                        // Stereo VU Meters
                        HStack(spacing: 6) {
                            VUMeterView(coordinator: coordinator, themeManager: themeManager, channelName: "L")
                            VUMeterView(coordinator: coordinator, themeManager: themeManager, channelName: "R")
                        }
                        .padding(.top, 14)

                        // Tonearm
                        TonearmView(coordinator: coordinator, themeManager: themeManager, height: 180)
                            .padding(.top, 4)
                    }
                    .padding(.trailing, 12)
                }

                Divider()
                    .background(Color.white.opacity(0.15))
                    .padding(.horizontal, 12)

                // Bottom Section: Playback Controls & Track Details
                TurntableControlsView(coordinator: coordinator, themeManager: themeManager)
            }
            .padding(.bottom, 6)
        }
        .frame(width: 460, height: 360)
        .sheet(isPresented: $themeManager.showLicenseModal) {
            licenseModalView
        }
    }

    // MARK: - License Modal View

    private var licenseModalView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundColor(.orange)

            Text("Unlock VinylDesk Pro")
                .font(.title2)
                .fontWeight(.bold)

            Text("Unlock all vintage skins (Vintage Walnut, Neon Acrylic, Cassette Deck), reactive VU meters, and custom vinyl scratch effects.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                TextField("Enter license key (e.g. VINYL-PRO-XXXX)", text: $viewState.licenseKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)

                if !viewState.licenseErrorMessage.isEmpty {
                    Text(viewState.licenseErrorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    themeManager.showLicenseModal = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Unlock Pro ($7.99)") {
                    if themeManager.unlockPro(licenseKey: viewState.licenseKeyInput) {
                        themeManager.showLicenseModal = false
                        viewState.licenseErrorMessage = ""
                    } else {
                        viewState.licenseErrorMessage = "Invalid key. Tip: use 'VINYL-PRO-DEMO'"
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 380, height: 270)
    }
}
