import Foundation
import VinylDeskCore

@main
struct TestRunner {
    @MainActor
    static func main() {
        print("▶ Running VinylDeskCore Test Suite...")
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

        // Test 4: Theme licensing
        test("Theme licensing validation") {
            let themeManager = ThemeManager.shared
            assert(!themeManager.isProUnlocked, "Default should be free tier")

            let invalidResult = themeManager.unlockPro(licenseKey: "INVALID-KEY-123")
            assert(!invalidResult, "Invalid key should fail")
            assert(!themeManager.isProUnlocked, "Pro should remain locked")

            let validResult = themeManager.unlockPro(licenseKey: "VINYL-PRO-DEMO-99")
            assert(validResult, "VINYL-PRO prefix should unlock")
            assert(themeManager.isProUnlocked, "Pro should be unlocked")
        }

        // Test 5: SoundFX engine initialization
        test("SoundFXEngine initialization") {
            let engine = SoundFXEngine.shared
            assert(engine.isCrackleEnabled, "Crackle should be enabled by default")
        }

        // Test 6: Demo track fallback
        test("Demo track fallback") {
            let demo = TrackInfo.demoTrack
            assert(demo.source == .demo, "Demo track should have demo source")
            assert(demo.duration > 0, "Demo track must have positive duration")
            assert(!demo.title.isEmpty, "Demo track must have title")
        }

        print("\n===============================")
        print("Test Suite Summary: \(passed) passed, \(failed) failed")
        print("===============================\n")

        if failed > 0 {
            exit(1)
        }
    }
}
