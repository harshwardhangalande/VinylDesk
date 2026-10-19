import Foundation
import VinylDeskCore

@main
struct TestRunner {
    @MainActor
    static func main() {
        print("▶ Running Sleeve / VinylDesk Test Suite...")
        var passed = 0
        var failed = 0

        func test(_ name: String, block: () throws -> Void) {
            do {
                try block()
                print("  ✓ \(name)")
                passed += 1
            } catch {
                print("  ✗ \(name) FAILED: \(error)")
                failed += 1
            }
        }

        // Test 1: Track progress calculation
        test("TrackInfo progress calculation") {
            let track = TrackInfo(
                title: "Test Song",
                artist: "Test Artist",
                album: "Test Album",
                duration: 200,
                position: 50
            )
            assert(abs(track.progress - 0.25) < 0.001, "Progress should be 0.25")
        }

        // Test 2: Track progress clamping
        test("TrackInfo progress clamping") {
            let trackOver = TrackInfo(
                title: "Test",
                artist: "Test",
                album: "Test",
                duration: 100,
                position: 150
            )
            assert(abs(trackOver.progress - 1.0) < 0.001, "Over-position should clamp to 1.0")

            let trackUnder = TrackInfo(
                title: "Test",
                artist: "Test",
                album: "Test",
                duration: 100,
                position: -50
            )
            assert(abs(trackUnder.progress - 0.0) < 0.001, "Under-position should clamp to 0.0")
        }

        // Test 3: Time formatting
        test("Time formatting") {
            assert(TrackInfo.formatTime(0) == "00:00", "0 should format as 00:00")
            assert(TrackInfo.formatTime(65) == "01:05", "65 should format as 01:05")
            assert(TrackInfo.formatTime(3599) == "59:59", "3599 should format as 59:59")
        }

        // Test 4: Demo track fallback
        test("Demo track fallback") {
            let demo = TrackInfo.demoTrack
            assert(demo.source == .demo, "Demo track should have demo source")
            assert(demo.duration > 0, "Demo track must have positive duration")
            assert(!demo.title.isEmpty, "Demo track must have title")
        }

        // Test 5: Sleeve Theme Presets Verification
        test("Sleeve 3 theme presets verification") {
            let presets = SleeveThemeConfig.allPresets
            assert(presets.count >= 6, "Must provide at least 6 presets (Stack, Ider, Cole, Minimal, Retro Vinyl, Wooden Shelf)")

            let names = presets.map { $0.name }
            assert(names.contains("Stack"), "Must contain Stack theme")
            assert(names.contains("Ider"), "Must contain Ider theme")
            assert(names.contains("Cole"), "Must contain Cole theme")
            assert(names.contains("Minimal"), "Must contain Minimal theme")
            assert(names.contains("Retro Vinyl"), "Must contain Retro Vinyl theme")
            assert(names.contains("Wooden Shelf"), "Must contain Wooden Shelf theme")
        }

        // Test 6: Sleeve Theme JSON Serialization & Deserialization
        test("Sleeve Theme JSON roundtrip export & import") {
            let originalTheme = SleeveThemeConfig.presetRetroVinyl
            let encoder = JSONEncoder()
            let data = try encoder.encode(originalTheme)
            let jsonString = String(data: data, encoding: .utf8)!
            assert(!jsonString.isEmpty, "Encoded JSON must not be empty")

            let decoder = JSONDecoder()
            let decodedTheme = try decoder.decode(SleeveThemeConfig.self, from: data)
            assert(decodedTheme.id == originalTheme.id, "Theme IDs must match")
            assert(decodedTheme.layout == .vintageVinyl, "Layout must be vintageVinyl")
            assert(decodedTheme.showSpinningRecord == true, "Spinning record must be enabled")
        }

        // Test 7: Sleeve Shadow and Corner Radius Attributes
        test("Shadow styles and corner radii") {
            assert(ShadowStyle.none.radius == 0, "None shadow must have 0 radius")
            assert(ShadowStyle.deep.radius > ShadowStyle.regular.radius, "Deep shadow radius must exceed regular")
            assert(ShadowStyle.deep.opacity > ShadowStyle.subtle.opacity, "Deep shadow opacity must exceed subtle")
        }

        // Test 8: Sleeve Theme Manager switching
        test("SleeveThemeManager preset switching") {
            let manager = SleeveThemeManager.shared
            manager.selectPreset(SleeveThemeConfig.presetWoodenShelf)
            assert(manager.currentTheme.name == "Wooden Shelf", "Active theme should be Wooden Shelf")
            assert(manager.currentTheme.layout == .woodenShelf, "Layout should be woodenShelf")

            manager.selectPreset(SleeveThemeConfig.presetStack)
            assert(manager.currentTheme.name == "Stack", "Active theme should be Stack")
        }

        // Test 9: Liquid Glass Intensity Levels & Attributes
        test("Liquid Glass levels and tint attributes") {
            assert(LiquidGlassLevel.allCases.count == 5, "Must provide 5 intensity levels (System, Low, Medium, High, Ultra)")
            assert(LiquidGlassLevel.ultra.blurRadius > LiquidGlassLevel.high.blurRadius, "Ultra blur must exceed High blur")
            assert(LiquidGlassLevel.high.blurRadius > LiquidGlassLevel.medium.blurRadius, "High blur must exceed Medium blur")
            assert(LiquidGlassLevel.medium.blurRadius > LiquidGlassLevel.low.blurRadius, "Medium blur must exceed Low blur")

            assert(LiquidGlassLevel.ultra.baseOpacity > LiquidGlassLevel.low.baseOpacity, "Ultra opacity must exceed Low opacity")
            assert(LiquidGlassLevel.ultra.rimShine > LiquidGlassLevel.low.rimShine, "Ultra rim shine must exceed Low rim shine")
            assert(LiquidGlassTint.allCases.count == 4, "Must provide 4 tint modes (Neutral, Album Dynamic, System Accent, Prismatic)")
        }

        // Test 10: Backward-Compatible Decoding without Liquid Glass fields
        test("Backward-compatible theme decoding without liquid glass fields") {
            let legacyJson = """
            {
                "id": "legacy-test-theme",
                "name": "Legacy Theme",
                "layout": "Horizontal",
                "backdropMaterial": "Glass"
            }
            """
            let data = legacyJson.data(using: .utf8)!
            let decoded = try JSONDecoder().decode(SleeveThemeConfig.self, from: data)
            assert(decoded.name == "Legacy Theme", "Name should decode properly")
            assert(decoded.liquidGlassLevel == .system, "Missing liquidGlassLevel should default to .system")
            assert(decoded.liquidGlassTint == .neutral, "Missing liquidGlassTint should default to .neutral")
            assert(decoded.liquidGlassFluidPulse == true, "Missing liquidGlassFluidPulse should default to true")
        }

        print("\n===============================")
        print("Test Suite Summary: \(passed) passed, \(failed) failed")
        print("===============================\n")

        if failed > 0 {
            exit(1)
        }
    }
}
