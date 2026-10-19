import SwiftUI
import Combine

@MainActor
public final class SleeveThemeManager: ObservableObject {
    public static let shared = SleeveThemeManager()

    private let userDefaultsKey = "VinylDesk.SleeveTheme.Current"
    private let userThemesKey = "VinylDesk.SleeveTheme.UserThemes"
    private let saveSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    @Published public var currentTheme: SleeveThemeConfig
    @Published public var presets: [SleeveThemeConfig]
    @Published public var userThemes: [SleeveThemeConfig] = []
    @Published public var isProUnlocked: Bool = true
    @Published public var previewLightMode: Bool = false
    @Published public var isPreviewHidden: Bool = false

    private init() {
        self.presets = SleeveThemeConfig.allPresets

        // Load custom user themes if any
        if let userThemesData = UserDefaults.standard.data(forKey: userThemesKey),
           let savedUserThemes = try? JSONDecoder().decode([SleeveThemeConfig].self, from: userThemesData) {
            self.userThemes = savedUserThemes
        } else {
            self.userThemes = []
        }

        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode(SleeveThemeConfig.self, from: data) {
            self.currentTheme = saved
        } else {
            self.currentTheme = SleeveThemeConfig.presetStack
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

    public func selectPreset(_ preset: SleeveThemeConfig) {
        self.currentTheme = preset
        persistThemeDirectly()
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
            self.currentTheme = presets.first ?? SleeveThemeConfig.presetStack
            persistThemeDirectly()
        }
    }

    private func persistUserThemes() {
        if let encoded = try? JSONEncoder().encode(userThemes) {
            UserDefaults.standard.set(encoded, forKey: userThemesKey)
        }
    }

    public func resetToDefault() {
        self.currentTheme = SleeveThemeConfig.presetStack
        persistThemeDirectly()
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
              let decoded = try? JSONDecoder().decode(SleeveThemeConfig.self, from: data) else {
            return false
        }
        self.currentTheme = decoded
        saveCurrentTheme()
        return true
    }
}
