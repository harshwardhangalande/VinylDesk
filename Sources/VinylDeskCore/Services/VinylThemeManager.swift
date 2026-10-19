import SwiftUI
import Combine

@MainActor
public final class VinylThemeManager: ObservableObject {
    public static let shared = VinylThemeManager()

    private let userDefaultsKey = "VinylDesk.VinylTheme.Current"
    private let userThemesKey = "VinylDesk.VinylTheme.UserThemes"
    private let saveSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    @Published public var currentTheme: VinylThemeConfig
    @Published public var presets: [VinylThemeConfig]
    @Published public var userThemes: [VinylThemeConfig] = []
    @Published public var isProUnlocked: Bool = true
    @Published public var previewLightMode: Bool = false
    @Published public var isPreviewHidden: Bool = false

    private init() {
        self.presets = VinylThemeConfig.allPresets

        // Load custom user themes if any (with legacy migration fallback)
        let legacyThemesKey = "VinylDesk.SleeveTheme.UserThemes"
        if let userThemesData = UserDefaults.standard.data(forKey: userThemesKey) ?? UserDefaults.standard.data(forKey: legacyThemesKey),
           let savedUserThemes = try? JSONDecoder().decode([VinylThemeConfig].self, from: userThemesData) {
            self.userThemes = savedUserThemes
        } else {
            self.userThemes = []
        }

        let legacyDefaultsKey = "VinylDesk.SleeveTheme.Current"
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) ?? UserDefaults.standard.data(forKey: legacyDefaultsKey),
           let saved = try? JSONDecoder().decode(VinylThemeConfig.self, from: data) {
            self.currentTheme = saved
        } else {
            self.currentTheme = VinylThemeConfig.presetStack
        }

        // Sync initial theme to widget storage
        SharedWidgetStorage.shared.saveTheme(self.currentTheme)

        saveSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.persistThemeDirectly()
            }
            .store(in: &cancellables)
    }

    public func applyTheme(_ theme: VinylThemeConfig, preserveUserPreferences: Bool = true) {
        if preserveUserPreferences {
            var updated = theme
            updated.visibility = self.currentTheme.visibility
            updated.windowPlacement = self.currentTheme.windowPlacement
            updated.showAlbumArtworkInDock = self.currentTheme.showAlbumArtworkInDock
            updated.floatOnTrackChange = self.currentTheme.floatOnTrackChange
            updated.experienceMode = self.currentTheme.experienceMode
            updated.isFloatingOverlayVisible = self.currentTheme.isFloatingOverlayVisible
            self.currentTheme = updated
        } else {
            self.currentTheme = theme
        }
        persistThemeDirectly()
    }

    public func selectPreset(_ preset: VinylThemeConfig) {
        applyTheme(preset, preserveUserPreferences: true)
    }

    public func saveCurrentTheme() {
        saveSubject.send()
    }

    public func persistThemeDirectly() {
        if let encoded = try? JSONEncoder().encode(currentTheme) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        // Sync live theme to Native macOS WidgetKit extension
        SharedWidgetStorage.shared.saveTheme(currentTheme)
    }

    // MARK: - User Themes Management

    public func saveCurrentAsCustomTheme(name: String? = nil) {
        let themeName = name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? name!
            : "\(currentTheme.name) (Custom)"

        var customTheme = currentTheme
        customTheme.id = "custom-" + UUID().uuidString
        customTheme.name = themeName

        userThemes.append(customTheme)
        persistUserThemes()
        self.currentTheme = customTheme
        persistThemeDirectly()
    }

    public func deleteCustomTheme(id: String) {
        userThemes.removeAll { $0.id == id }
        persistUserThemes()

        if currentTheme.id == id {
            applyTheme(presets.first ?? VinylThemeConfig.presetStack, preserveUserPreferences: true)
        }
    }

    private func persistUserThemes() {
        if let encoded = try? JSONEncoder().encode(userThemes) {
            UserDefaults.standard.set(encoded, forKey: userThemesKey)
        }
    }

    public func resetToDefault() {
        applyTheme(VinylThemeConfig.presetStack, preserveUserPreferences: true)
    }

    public func exportThemeJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(currentTheme),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return nil
    }

    public func importThemeJSON(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(VinylThemeConfig.self, from: data) else {
            return false
        }
        self.currentTheme = decoded
        saveCurrentTheme()
        return true
    }
}
