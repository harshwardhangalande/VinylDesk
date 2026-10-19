import SwiftUI

public struct HotkeysInspectorView: View {
    @ObservedObject var themeManager: SleeveThemeManager

    @MainActor
    public init(themeManager: SleeveThemeManager) {
        self.themeManager = themeManager
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SleeveSectionCard {
                    Text("Keyboard Shortcuts")
                        .font(.system(size: 13, weight: .semibold))

                    Text("Control playback, like tracks, and adjust music from anywhere with global shortcuts.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    VStack(spacing: 8) {
                        shortcutRow(label: "Play/Pause", shortcut: "⇧ ⌘ ↑")
                        shortcutRow(label: "Next Track", shortcut: "⇧ ⌘ →")
                        shortcutRow(label: "Previous Track", shortcut: "⇧ ⌘ ←")
                        shortcutRow(label: "Volume Up", shortcut: "⌥ ⌘ ↑")
                        shortcutRow(label: "Volume Down", shortcut: "⌥ ⌘ ↓")
                        shortcutRow(label: "Favorite Track", shortcut: "⌥ ⌘ F")
                    }
                }

                SleeveSectionCard {
                    Text("Dock & Menu Bar")
                        .font(.system(size: 13, weight: .semibold))

                    Toggle("Show Icon in Dock", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle())

                    Toggle("Show Album Artwork in Dock", isOn: Binding(
                        get: { themeManager.currentTheme.showAlbumArtworkInDock },
                        set: { newValue in
                            themeManager.currentTheme.showAlbumArtworkInDock = newValue
                            themeManager.saveCurrentTheme()
                            DockIconManager.shared.updateDockIcon(
                                artworkData: MusicCoordinator.shared.currentTrack.artworkData,
                                isEnabled: newValue
                            )
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle())

                    Text("Custom App Icon")
                        .font(.system(size: 12))
                        .padding(.top, 4)

                    HStack(spacing: 12) {
                        iconOption(title: "Default", isSelected: true, color: .blue)
                        iconOption(title: "Nostalgia", isSelected: false, color: .teal)
                        iconOption(title: "Original", isSelected: false, color: .indigo)
                    }
                }
            }
            .padding(16)
        }
    }

    private func shortcutRow(label: String, shortcut: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
            Spacer()
            Text(shortcut)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.22)))
        }
        .padding(.vertical, 2)
    }

    private func iconOption(title: String, isSelected: Bool, color: Color) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundColor(.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.blue : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                )

            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? Color.blue : Color.secondary)
        }
    }
}
