import SwiftUI
import Combine

@MainActor
public final class SleeveThemeManager: ObservableObject {
    public static let shared = SleeveThemeManager()

    private let userDefaultsKey = "VinylDesk.SleeveTheme.Current"
    private let saveSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    @Published public var currentTheme: SleeveThemeConfig
    @Published public var presets: [SleeveThemeConfig]
    @Published public var isProUnlocked: Bool = true
    @Published public var previewLightMode: Bool = false
    @Published public var isPreviewHidden: Bool = false

    private init() {
        self.presets = SleeveThemeConfig.allPresets
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode(SleeveThemeConfig.self, from: data) {
            self.currentTheme = saved
        } else {
            self.currentTheme = SleeveThemeConfig.presetStack
        }

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
