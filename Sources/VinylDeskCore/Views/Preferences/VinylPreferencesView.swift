import SwiftUI

public enum PreferencesTab: String, CaseIterable, Identifiable {
    case themes = "Themes"
    case layout = "Layout"
    case artwork = "Artwork"
    case interface = "Interface"
    case typography = "Track Info"
    case position = "Position"
    case hotkeys = "Hotkeys"
    case system = "System"

    public var id: String { rawValue }

    public var systemImage: String {
        switch self {
        case .themes: return "wand.and.stars"
        case .layout: return "square.grid.2x2"
        case .artwork: return "photo"
        case .interface: return "play.circle"
        case .typography: return "textformat"
        case .position: return "arrow.up.and.down.and.arrow.left.and.right"
        case .hotkeys: return "command"
        case .system: return "gearshape"
        }
    }
}

public struct VinylPreferencesView: View {
    @ObservedObject var themeManager: VinylThemeManager
    @ObservedObject var coordinator: MusicCoordinator
    @StateObject private var windowState = PreferencesWindowState()

    @MainActor
    public init(
        themeManager: VinylThemeManager,
        coordinator: MusicCoordinator
    ) {
        self.themeManager = themeManager
        self.coordinator = coordinator
    }

    public var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Sidebar
            sidebarView
                .frame(width: 190)
                .fixedSize(horizontal: true, vertical: false)
                .background(Color(white: 0.11))
                .layoutPriority(2)

            Divider().background(Color.white.opacity(0.1))

            // MARK: - Center Inspector
            VStack(spacing: 0) {
                // Inspector Header
                HStack(spacing: 10) {
                    Text(windowState.selectedTab.rawValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    // Quick reset button
                    Button(action: {
                        themeManager.resetToDefault()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Reset to defaults")

                    // Toggle Live Preview button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            windowState.showLivePreview.toggle()
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: windowState.showLivePreview ? "eye.fill" : "eye.slash.fill")
                                .font(.system(size: 12))
                            if !windowState.showLivePreview {
                                Text("Show Preview")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .foregroundColor(windowState.showLivePreview ? .secondary : .cyan)
                        .padding(.horizontal, windowState.showLivePreview ? 4 : 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(windowState.showLivePreview ? Color.clear : Color.cyan.opacity(0.18))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(windowState.showLivePreview ? "Hide Preview Canvas" : "Show Preview Canvas")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(white: 0.13))

                Divider().background(Color.white.opacity(0.08))

                // Inspector Body
                Group {
                    switch windowState.selectedTab {
                    case .themes:
                        ThemesInspectorView(themeManager: themeManager)
                    case .layout:
                        LayoutInspectorView(themeManager: themeManager)
                    case .artwork:
                        ArtworkInspectorView(themeManager: themeManager)
                    case .interface:
                        InterfaceInspectorView(themeManager: themeManager)
                    case .typography:
                        TypographyInspectorView(themeManager: themeManager)
                    case .position:
                        PositionInspectorView(themeManager: themeManager)
                    case .hotkeys, .system:
                        HotkeysInspectorView(themeManager: themeManager)
                    }
                }
                .frame(maxWidth: windowState.showLivePreview ? 320 : 640)
            }
            .frame(minWidth: 320, maxWidth: windowState.showLivePreview ? 320 : .infinity)
            .background(Color(white: 0.12))
            .layoutPriority(1)

            // MARK: - Right Live Preview Canvas
            if windowState.showLivePreview {
                Divider().background(Color.white.opacity(0.1))

                livePreviewCanvas
                    .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(0)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(minWidth: windowState.showLivePreview ? 980 : 540, minHeight: 620)
    }

    // MARK: - Sidebar View

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Search Bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                TextField("Search", text: $windowState.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.18)))
            .padding(.horizontal, 12)
            .padding(.top, 14)

            // Sidebar Tabs
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    sidebarRow(tab: .themes)

                    Text("Theme")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        .padding(.bottom, 2)

                    sidebarRow(tab: .layout)
                    sidebarRow(tab: .artwork)
                    sidebarRow(tab: .interface)
                    sidebarRow(tab: .typography)

                    Text("Settings")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        .padding(.bottom, 2)

                    sidebarRow(tab: .position)
                    sidebarRow(tab: .hotkeys)
                    sidebarRow(tab: .system)
                }
                .padding(.horizontal, 8)
            }

            Spacer()

            // Source Selector Pill in Sidebar Footer
            VStack(alignment: .leading, spacing: 4) {
                Text("Music Source")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    Image(systemName: coordinator.currentTrack.source == .spotify ? "waveform.circle.fill" : "music.note")
                        .foregroundColor(.green)
                    Text(coordinator.currentTrack.source.rawValue)
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.18)))
            }
            .padding(12)
        }
    }

    private func sidebarRow(tab: PreferencesTab) -> some View {
        Button(action: { windowState.selectedTab = tab }) {
            HStack(spacing: 8) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 12))
                    .foregroundColor(windowState.selectedTab == tab ? .white : .secondary)
                    .frame(width: 18)

                Text(tab.rawValue)
                    .font(.system(size: 12, weight: windowState.selectedTab == tab ? .semibold : .regular))
                    .foregroundColor(windowState.selectedTab == tab ? .white : .primary.opacity(0.85))

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(windowState.selectedTab == tab ? Color.blue : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Live Preview Canvas

    private var livePreviewCanvas: some View {
        ZStack {
            // Wallpaper Background Simulation
            if windowState.previewIsLightMode {
                LinearGradient(
                    colors: [
                        Color(red: 0.82, green: 0.88, blue: 0.94),
                        Color(red: 0.70, green: 0.76, blue: 0.86),
                        Color(red: 0.88, green: 0.91, blue: 0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.12, blue: 0.28),
                        Color(red: 0.05, green: 0.06, blue: 0.16),
                        Color(red: 0.18, green: 0.12, blue: 0.32)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            // Canvas Toolbar at top
            VStack {
                HStack(spacing: 12) {
                    Button(action: {
                        coordinator.seek(to: 0)
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(6)
                            .background(Circle().fill(Color.black.opacity(0.35)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    // Light / Dark mode toggle
                    Button(action: { windowState.previewIsLightMode.toggle() }) {
                        Image(systemName: windowState.previewIsLightMode ? "moon.fill" : "sun.max.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(6)
                            .background(Circle().fill(Color.black.opacity(0.35)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Hide preview toggle
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            windowState.showLivePreview = false
                        }
                    }) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(6)
                            .background(Circle().fill(Color.black.opacity(0.35)))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Hide Live Preview")
                }
                .padding(14)

                Spacer()
            }
            .zIndex(2)

            // The Live Widget Centerpiece (auto-fitted and centered)
            GeometryReader { geo in
                let availableWidth = max(60, geo.size.width - 48)
                let availableHeight = max(60, geo.size.height - 84)

                FittedWidgetPreview(
                    coordinator: coordinator,
                    theme: themeManager.currentTheme,
                    isLightBackground: windowState.previewIsLightMode,
                    maxWidth: availableWidth,
                    maxHeight: availableHeight
                )
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            }
            .padding(12)
        }
        .clipped()
    }
}

// MARK: - Auto-Fitted Widget Preview

struct FittedWidgetPreview: View {
    @ObservedObject var coordinator: MusicCoordinator
    let theme: VinylThemeConfig
    let isLightBackground: Bool
    let maxWidth: CGFloat
    let maxHeight: CGFloat

    @StateObject private var widgetState = FittedWidgetState()

    private var scaleFactor: CGFloat {
        guard widgetState.measuredWidth > 0, widgetState.measuredHeight > 0 else { return 1.0 }
        let scaleX = maxWidth / widgetState.measuredWidth
        let scaleY = maxHeight / widgetState.measuredHeight
        return min(1.0, min(scaleX, scaleY))
    }

    var body: some View {
        ZStack {
            VinylWidgetView(
                coordinator: coordinator,
                theme: theme,
                isLightBackground: isLightBackground
            )
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: PreviewWidgetSizePreferenceKey.self, value: proxy.size)
                }
            )
            .shadow(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 12)
            .scaleEffect(scaleFactor)
            .animation(.easeInOut(duration: 0.15), value: scaleFactor)
        }
        .onPreferenceChange(PreviewWidgetSizePreferenceKey.self) { newSize in
            if newSize != .zero && (abs(newSize.width - widgetState.measuredWidth) > 1 || abs(newSize.height - widgetState.measuredHeight) > 1) {
                widgetState.measuredWidth = newSize.width
                widgetState.measuredHeight = newSize.height
            }
        }
    }
}

private struct PreviewWidgetSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}
