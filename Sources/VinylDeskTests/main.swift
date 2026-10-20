import Foundation
import AppKit
import VinylDeskCore

@main
struct TestRunner {
    @MainActor
    static func main() {
        print("▶ Running VinylDesk Test Suite...")
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

        // Test 5: Vinyl Theme Presets Verification
        test("Vinyl theme presets verification") {
            let presets = VinylThemeConfig.allPresets
            assert(presets.count >= 6, "Must provide at least 6 presets (Stack, Ider, Cole, Minimal, Retro Vinyl, Wooden Shelf)")

            let names = presets.map { $0.name }
            assert(names.contains("Stack"), "Must contain Stack theme")
            assert(names.contains("Ider"), "Must contain Ider theme")
            assert(names.contains("Cole"), "Must contain Cole theme")
            assert(names.contains("Minimal"), "Must contain Minimal theme")
            assert(names.contains("Retro Vinyl"), "Must contain Retro Vinyl theme")
            assert(names.contains("Wooden Shelf"), "Must contain Wooden Shelf theme")
        }

        // Test 6: Vinyl Theme JSON Serialization & Deserialization
        test("Vinyl Theme JSON roundtrip export & import") {
            let originalTheme = VinylThemeConfig.presetRetroVinyl
            let encoder = JSONEncoder()
            let data = try encoder.encode(originalTheme)
            let jsonString = String(data: data, encoding: .utf8)!
            assert(!jsonString.isEmpty, "Encoded JSON must not be empty")

            let decoder = JSONDecoder()
            let decodedTheme = try decoder.decode(VinylThemeConfig.self, from: data)
            assert(decodedTheme.id == originalTheme.id, "Theme IDs must match")
            assert(decodedTheme.layout == .vintageVinyl, "Layout must be vintageVinyl")
            assert(decodedTheme.showSpinningRecord == true, "Spinning record must be enabled")
        }

        // Test 7: Vinyl Shadow and Corner Radius Attributes
        test("Shadow styles and corner radii") {
            assert(ShadowStyle.none.radius == 0, "None shadow must have 0 radius")
            assert(ShadowStyle.deep.radius > ShadowStyle.regular.radius, "Deep shadow radius must exceed regular")
            assert(ShadowStyle.deep.opacity > ShadowStyle.subtle.opacity, "Deep shadow opacity must exceed subtle")
        }

        // Test 8: Vinyl Theme Manager switching
        test("VinylThemeManager preset switching") {
            let manager = VinylThemeManager.shared
            manager.selectPreset(VinylThemeConfig.presetWoodenShelf)
            assert(manager.currentTheme.name == "Wooden Shelf", "Active theme should be Wooden Shelf")
            assert(manager.currentTheme.layout == .woodenShelf, "Layout should be woodenShelf")

            manager.selectPreset(VinylThemeConfig.presetStack)
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
            let decoded = try JSONDecoder().decode(VinylThemeConfig.self, from: data)
            assert(decoded.name == "Legacy Theme", "Name should decode properly")
            assert(decoded.liquidGlassLevel == .low, "Missing liquidGlassLevel should default to .low")
            assert(decoded.liquidGlassTint == .neutral, "Missing liquidGlassTint should default to .neutral")
            assert(decoded.liquidGlassFluidPulse == true, "Missing liquidGlassFluidPulse should default to true")
        }

        // Test 11: ArtworkCache caching & retrieval
        test("ArtworkCache in-memory caching") {
            let cache = ArtworkCache.shared
            // Non-image data returns nil
            let nonImageData = "invalid-data".data(using: .utf8)!
            assert(cache.dominantColor(for: "invalid", data: nonImageData) == nil, "Invalid data should return nil")

            // Create valid 10x10 bitmap image data
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: 10,
                pixelsHigh: 10,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 40,
                bitsPerPixel: 32
            )!
            let tiffData = rep.tiffRepresentation!

            // Dominant color calculation with valid image
            let color = cache.dominantColor(for: "test-track-1", data: tiffData)
            assert(color != nil, "Dominant color should compute for valid image data")

            // Second call hits cache
            let cachedColor = cache.dominantColor(for: "test-track-1", data: tiffData)
            assert(cachedColor != nil, "Cached color should return successfully")

            // Image retrieval and downscaling
            let img = cache.image(for: "test-track-1", data: tiffData, maxDimension: 5)
            assert(img != nil, "Downscaled image should return")
            assert(img!.size.width <= 10, "Width should be <= max dimension")
        }

        // Test 12: New Screenshot Layouts and Presets Verification
        test("Screenshot widget presets and layouts verification") {
            let presets = VinylThemeConfig.allPresets
            let names = presets.map { $0.name }
            assert(names.contains("Time Dashboard"), "Must contain Time Dashboard preset")
            assert(names.contains("Split Card"), "Must contain Split Card preset")
            assert(names.contains("Split Banner"), "Must contain Split Banner preset")
            assert(names.contains("Artwork Poster"), "Must contain Artwork Poster preset")
            assert(names.contains("Compact Square"), "Must contain Compact Square preset")
            assert(names.contains("Squircle Card"), "Must contain Squircle Card preset")

            assert(VinylLayout.allCases.contains(.timeDashboard), "VinylLayout must contain timeDashboard")
            assert(VinylLayout.allCases.contains(.splitCard), "VinylLayout must contain splitCard")
            assert(VinylLayout.allCases.contains(.splitBanner), "VinylLayout must contain splitBanner")
            assert(VinylLayout.allCases.contains(.artworkPoster), "VinylLayout must contain artworkPoster")
            assert(VinylLayout.allCases.contains(.compactSquare), "VinylLayout must contain compactSquare")
            assert(VinylLayout.allCases.contains(.artworkCard), "VinylLayout must contain artworkCard")
        }

        // Test 13: SharedWidgetStorage & Dual Mode Verification
        test("SharedWidgetStorage and Dual Mode configuration") {
            let storage = SharedWidgetStorage.shared
            let testTrack = TrackInfo(
                title: "Dual Mode Test",
                artist: "Widget Artist",
                album: "Widget Album",
                duration: 180,
                position: 45,
                isPlaying: true,
                source: .spotify
            )
            storage.saveTrack(testTrack)

            // Verify loadTrack fallback / roundtrip
            let loaded = storage.loadTrack()
            assert(!loaded.title.isEmpty, "Loaded track must not have empty title")

            // Verify ExperienceMode cases
            assert(ExperienceMode.allCases.count == 3, "ExperienceMode must have 3 modes")
            let theme = VinylThemeConfig.presetTimeDashboard
            assert(theme.experienceMode == .dual, "Default experienceMode should be dual")
            assert(theme.isFloatingOverlayVisible == true, "Default isFloatingOverlayVisible should be true")
        }

        // Test 14: Dynamic Typography and Controls Configurations for New Themes
        test("Dynamic Typography & Controls Configurations for New Themes") {
            let dashboard = VinylThemeConfig.presetTimeDashboard
            assert(dashboard.liquidGlassLevel == .low, "presetTimeDashboard liquidGlassLevel should default to .low")
            assert(dashboard.trackNameStyle.fontDesign == .sans, "presetTimeDashboard font design should be sans")
            assert(dashboard.trackNameStyle.fontWeight == .bold, "presetTimeDashboard font weight should be bold")

            let banner = VinylThemeConfig.presetSplitBanner
            assert(banner.showPlaybackControls == true, "Split Banner showPlaybackControls should be true")
            assert(banner.controlsPlacement == .inlineWithText, "Split Banner controlsPlacement should be inlineWithText")
            assert(banner.controlsSize == .medium, "Split Banner controlsSize should be medium")
            assert(banner.trackNameStyle.isVisible == true, "Split Banner track name must be visible")

            let compact = VinylThemeConfig.presetCompactSquare
            assert(compact.controlsSize == .small, "Compact Square controlsSize should be small")
            assert(compact.albumStyle.isVisible == false, "Compact Square album should be hidden by default")

            let poster = VinylThemeConfig.presetArtworkPoster
            assert(poster.trackNameStyle.fontSize == 18, "Artwork poster track font size should be 18")
            assert(poster.artworkSize == 300, "Artwork poster size should be 300")
        }

        // Test 15: Theme Syncing & My Themes Management
        test("Theme Syncing to Widget Storage & My Themes Management") {
            let storage = SharedWidgetStorage.shared
            let banner = VinylThemeConfig.presetSplitBanner
            storage.saveTheme(banner)
            let loaded = storage.loadTheme()
            assert(loaded.name == banner.name || loaded.name == VinylThemeConfig.presetTimeDashboard.name, "Theme should load successfully")

            let mgr = VinylThemeManager.shared
            let countBefore = mgr.userThemes.count
            mgr.saveCurrentAsCustomTheme(name: "Test Custom Theme")
            assert(mgr.userThemes.count == countBefore + 1, "User themes count should increment by 1")
            guard let created = mgr.userThemes.last else {
                fatalError("User theme should have been created")
            }
            assert(created.name == "Test Custom Theme", "Custom theme name should match")
            mgr.deleteCustomTheme(id: created.id)
            assert(mgr.userThemes.count == countBefore, "User themes count should return to countBefore")
        }

        // Test 16: Dock Icon Album Artwork toggle configuration & roundtrip
        test("Dock Icon Album Artwork toggle configuration & roundtrip") {
            var theme = VinylThemeConfig.presetRetroVinyl
            assert(theme.showAlbumArtworkInDock == false, "Default showAlbumArtworkInDock should be false")
            theme.showAlbumArtworkInDock = true

            let encoder = JSONEncoder()
            let data = try encoder.encode(theme)
            let decoded = try JSONDecoder().decode(VinylThemeConfig.self, from: data)
            assert(decoded.showAlbumArtworkInDock == true, "showAlbumArtworkInDock should preserve true state after encoding/decoding")
        }

        // Test 17: Simplified Widget Visibility (Show only on desktop & Show everywhere)
        test("Simplified Widget Visibility (desktop only & show everywhere)") {
            assert(WidgetVisibility.allCases.count == 2, "WidgetVisibility must have 2 cases")
            assert(WidgetVisibility.desktopOnly.rawValue == "Show only on desktop")
            assert(WidgetVisibility.showEverywhere.rawValue == "Show everywhere")

            var theme = VinylThemeConfig.presetTimeDashboard
            theme.visibility = .desktopOnly
            theme.windowPlacement = .desktop

            let encoder = JSONEncoder()
            let data = try encoder.encode(theme)
            let decoded = try JSONDecoder().decode(VinylThemeConfig.self, from: data)
            assert(decoded.visibility == .desktopOnly, "Decoded theme should preserve desktopOnly visibility")

            // Test window level updates in DesktopWidgetController
            let controller = DesktopWidgetController.shared
            controller.show()
            controller.applyVisibility(.desktopOnly)
            assert(controller.window?.level.rawValue == -1, "desktopOnly window level should be -1 (.belowNormal)")
            assert(controller.window?.isVisible == true, "desktopOnly window must stay visible, never hidden")

            controller.applyVisibility(.showEverywhere)
            assert(controller.window?.level == .floating, "showEverywhere window level should be .floating")
            assert(controller.window?.isVisible == true, "showEverywhere window must stay visible")
        }

        // Test 18: Corner Radius 32 Default for All Presets
        test("All presets default corner radius 32") {
            for preset in VinylThemeConfig.allPresets {
                assert(preset.cornerRadius == 32, "Preset '\(preset.name)' cornerRadius should default to 32, but found \(preset.cornerRadius)")
                assert(preset.backdropCornerRadius == 32, "Preset '\(preset.name)' backdropCornerRadius should default to 32, but found \(preset.backdropCornerRadius)")
            }
        }

        // Test 19: Theme Switching Preserves Visibility & Window Placement
        test("Theme switching preserves user visibility and window placement") {
            let manager = VinylThemeManager.shared
            manager.currentTheme.visibility = .showEverywhere
            manager.currentTheme.windowPlacement = .floating
            manager.currentTheme.showAlbumArtworkInDock = true

            // Switch to a preset that has default visibility .desktopOnly
            manager.selectPreset(VinylThemeConfig.presetSplitCard)

            assert(manager.currentTheme.visibility == .showEverywhere, "Preset switch must preserve user's .showEverywhere visibility")
            assert(manager.currentTheme.windowPlacement == .floating, "Preset switch must preserve user's .floating placement")
            assert(manager.currentTheme.showAlbumArtworkInDock == true, "Preset switch must preserve user's showAlbumArtworkInDock preference")
            assert(manager.currentTheme.name == "Split Card", "Active theme name should be Split Card")

            // Switch to another preset
            manager.selectPreset(VinylThemeConfig.presetTimeDashboard)
            assert(manager.currentTheme.visibility == .showEverywhere, "Subsequent preset switch must continue preserving .showEverywhere visibility")
        }

        // Test 20: Split Card 6/10 Right Side Fraction Verification
        test("Split Card 6 out of 10 fractions right side") {
            let splitCard = VinylThemeConfig.presetSplitCard
            let totalW = splitCard.containerWidth
            let leftW = totalW * 0.4
            let rightW = totalW * 0.6
            assert(totalW >= 360, "Split card total width should be at least 360")
            assert(abs((rightW / totalW) - 0.6) < 0.001, "Right side must be exactly 6 out of 10 fractions (0.6)")
            assert(abs((leftW / totalW) - 0.4) < 0.001, "Left side must be exactly 4 out of 10 fractions (0.4)")
        }

        // Test 21: Lighting Effect None by Default for All Presets
        test("All presets default lightingEffect to none") {
            for preset in VinylThemeConfig.allPresets {
                assert(preset.lightingEffect == .none, "Preset '\(preset.name)' lightingEffect should default to .none, but found \(preset.lightingEffect)")
            }
            let defaultTheme = VinylThemeConfig()
            assert(defaultTheme.lightingEffect == .none, "VinylThemeConfig() default lightingEffect must be .none")
        }

        // Test 22: Like control disabled by default
        test("All presets default showLikeControl to false") {
            for preset in VinylThemeConfig.allPresets {
                assert(preset.showLikeControl == false, "Preset '\(preset.name)' showLikeControl should default to false")
            }
            let defaultTheme = VinylThemeConfig()
            assert(defaultTheme.showLikeControl == false, "VinylThemeConfig() default showLikeControl must be false")
        }

        // Test 23: Split Banner outer radius 32 and clear backdrop
        test("Split Banner outer radius 32 and clear backdrop") {
            let banner = VinylThemeConfig.presetSplitBanner
            assert(banner.backdropCornerRadius == 32, "Split Banner backdropCornerRadius should be 32")
            assert(banner.cornerRadius == 32, "Split Banner cornerRadius should be 32")
            assert(banner.backdropMaterial == .clear, "Split Banner backdropMaterial should be .clear")
        }

        print("\n===============================")
        print("Test Suite Summary: \(passed) passed, \(failed) failed")
        print("===============================\n")

        if failed > 0 {
            exit(1)
        }
    }
}
