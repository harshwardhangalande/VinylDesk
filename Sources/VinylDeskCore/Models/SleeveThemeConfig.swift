import SwiftUI
import AppKit

// MARK: - Layout Enums

public enum SleeveLayout: String, CaseIterable, Codable, Sendable {
    case horizontal = "Horizontal"
    case vertical = "Vertical"
    case stacked = "Stacked"
    case textOnly = "Text only"
    case vintageVinyl = "Retro Vinyl"
    case woodenShelf = "Wooden Shelf"
}

public enum HorizontalAlign: String, CaseIterable, Codable, Sendable {
    case left = "Left"
    case center = "Center"
    case right = "Right"

    public var textAlignment: TextAlignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }

    public var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }
}

public enum VerticalAlign: String, CaseIterable, Codable, Sendable {
    case top = "Top"
    case middle = "Middle"
    case bottom = "Bottom"
}

public enum ShadowStyle: String, CaseIterable, Codable, Sendable {
    case none = "None"
    case subtle = "Subtle"
    case regular = "Regular"
    case deep = "Deep"

    public var radius: CGFloat {
        switch self {
        case .none: return 0
        case .subtle: return 8
        case .regular: return 16
        case .deep: return 28
        }
    }

    public var yOffset: CGFloat {
        switch self {
        case .none: return 0
        case .subtle: return 4
        case .regular: return 10
        case .deep: return 18
        }
    }

    public var opacity: Double {
        switch self {
        case .none: return 0
        case .subtle: return 0.25
        case .regular: return 0.40
        case .deep: return 0.65
        }
    }
}

public enum LightingEffect: String, CaseIterable, Codable, Sendable {
    case none = "None"
    case spotlight = "Spotlight"
    case glare = "Glare"
}

public enum FontFamilyDesign: String, CaseIterable, Codable, Sendable {
    case sans = "Sans"
    case serif = "Serif"
    case round = "Round"
    case mono = "Mono"

    public var fontDesign: Font.Design {
        switch self {
        case .sans: return .default
        case .serif: return .serif
        case .round: return .rounded
        case .mono: return .monospaced
        }
    }
}

public enum FontWeightPreset: String, CaseIterable, Codable, Sendable {
    case regular = "Regular"
    case medium = "Medium"
    case semibold = "Semibold"
    case bold = "Bold"

    public var fontWeight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}

public enum ControlsPlacement: String, CaseIterable, Codable, Sendable {
    case onHover = "On artwork hover"
    case inlineWithText = "Inline with text"
}

public enum ControlsSize: String, CaseIterable, Codable, Sendable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    public var buttonPadding: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 12
        }
    }

    public var iconSize: CGFloat {
        switch self {
        case .small: return 11
        case .medium: return 14
        case .large: return 18
        }
    }
}

// MARK: - Liquid Glass Levels & Materials

public enum LiquidGlassLevel: String, CaseIterable, Codable, Sendable {
    case system = "System"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case ultra = "Ultra"

    public var displayName: String {
        switch self {
        case .system: return "System Level"
        case .low: return "Low (15%)"
        case .medium: return "Medium (30%)"
        case .high: return "High (50%)"
        case .ultra: return "Ultra / Liquid (70%)"
        }
    }

    public var blurRadius: CGFloat {
        switch self {
        case .system: return 28
        case .low: return 12
        case .medium: return 22
        case .high: return 36
        case .ultra: return 52
        }
    }

    public var baseOpacity: CGFloat {
        switch self {
        case .system:
            return NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency ? 0.92 : 0.35
        case .low: return 0.18
        case .medium: return 0.32
        case .high: return 0.52
        case .ultra: return 0.72
        }
    }

    public var rimShine: CGFloat {
        switch self {
        case .system: return 0.40
        case .low: return 0.22
        case .medium: return 0.45
        case .high: return 0.65
        case .ultra: return 0.88
        }
    }

    public var visualEffectMaterial: NSVisualEffectView.Material {
        switch self {
        case .system: return .underWindowBackground
        case .low: return .hudWindow
        case .medium: return .popover
        case .high: return .sheet
        case .ultra: return .fullScreenUI
        }
    }
}

public enum LiquidGlassTint: String, CaseIterable, Codable, Sendable {
    case neutral = "Neutral"
    case albumArt = "Album Dynamic"
    case systemAccent = "System Accent"
    case prismatic = "Prismatic"
}

public enum BackdropMaterial: String, CaseIterable, Codable, Sendable {
    case blur = "Blur"
    case glass = "Glass"
    case liquidGlass = "Liquid Glass"
    case solid = "Solid"
    case clear = "Clear"
}

public enum ShelfFinish: String, CaseIterable, Codable, Sendable {
    case lightOak = "Light Oak"
    case darkWalnut = "Dark Walnut"
    case matteBlack = "Matte Black"
    case neonAcrylic = "Neon Acrylic"
}

public enum WindowLevelPlacement: String, CaseIterable, Codable, Sendable {
    case desktop = "Keep on Desktop"
    case floating = "Above all windows"
}

// MARK: - Typography Line Config

public struct TypographyLineConfig: Codable, Equatable, Sendable {
    public var isVisible: Bool
    public var fontDesign: FontFamilyDesign
    public var fontWeight: FontWeightPreset
    public var fontSize: CGFloat
    public var isWhiteText: Bool
    public var shadow: ShadowStyle

    public init(
        isVisible: Bool = true,
        fontDesign: FontFamilyDesign = .sans,
        fontWeight: FontWeightPreset = .medium,
        fontSize: CGFloat = 14,
        isWhiteText: Bool = true,
        shadow: ShadowStyle = .subtle
    ) {
        self.isVisible = isVisible
        self.fontDesign = fontDesign
        self.fontWeight = fontWeight
        self.fontSize = fontSize
        self.isWhiteText = isWhiteText
        self.shadow = shadow
    }
}

// MARK: - Master Sleeve Theme Config

public struct SleeveThemeConfig: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var name: String

    // Layout
    public var layout: SleeveLayout
    public var flipHorizontal: Bool
    public var horizontalAlign: HorizontalAlign
    public var verticalAlign: VerticalAlign
    public var containerWidth: CGFloat

    // Artwork
    public var artworkSize: CGFloat // 80 - 240
    public var cornerRadius: CGFloat // 0 - 32
    public var artworkShadow: ShadowStyle
    public var lightingEffect: LightingEffect
    public var showSpinningRecord: Bool
    public var shelfFinish: ShelfFinish

    // Interface
    public var backdropMaterial: BackdropMaterial
    public var backdropCornerRadius: CGFloat
    public var showPlaybackControls: Bool
    public var controlsPlacement: ControlsPlacement
    public var controlsSize: ControlsSize
    public var showLikeControl: Bool
    public var showProgressBar: Bool

    // Typography
    public var trackNameStyle: TypographyLineConfig
    public var artistStyle: TypographyLineConfig
    public var albumStyle: TypographyLineConfig

    // Window & Behavior
    public var windowPlacement: WindowLevelPlacement
    public var floatOnTrackChange: Bool

    // Liquid Glass Configuration
    public var liquidGlassLevel: LiquidGlassLevel
    public var liquidGlassTint: LiquidGlassTint
    public var liquidGlassFluidPulse: Bool
    public var liquidGlassCustomOpacity: CGFloat // 0 means use level default
    public var liquidGlassCustomBlur: CGFloat // 0 means use level default
    public var liquidGlassRimShine: CGFloat // 0 means use level default

    public init(
        id: String = UUID().uuidString,
        name: String = "Custom Theme",
        layout: SleeveLayout = .horizontal,
        flipHorizontal: Bool = false,
        horizontalAlign: HorizontalAlign = .left,
        verticalAlign: VerticalAlign = .middle,
        containerWidth: CGFloat = 200,
        artworkSize: CGFloat = 140,
        cornerRadius: CGFloat = 12,
        artworkShadow: ShadowStyle = .regular,
        lightingEffect: LightingEffect = .spotlight,
        showSpinningRecord: Bool = false,
        shelfFinish: ShelfFinish = .darkWalnut,
        backdropMaterial: BackdropMaterial = .glass,
        backdropCornerRadius: CGFloat = 20,
        showPlaybackControls: Bool = true,
        controlsPlacement: ControlsPlacement = .onHover,
        controlsSize: ControlsSize = .medium,
        showLikeControl: Bool = true,
        showProgressBar: Bool = true,
        trackNameStyle: TypographyLineConfig = TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .bold, fontSize: 15, isWhiteText: true, shadow: .subtle),
        artistStyle: TypographyLineConfig = TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .medium, fontSize: 13, isWhiteText: true, shadow: .subtle),
        albumStyle: TypographyLineConfig = TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .regular, fontSize: 12, isWhiteText: true, shadow: .none),
        windowPlacement: WindowLevelPlacement = .desktop,
        floatOnTrackChange: Bool = false,
        liquidGlassLevel: LiquidGlassLevel = .system,
        liquidGlassTint: LiquidGlassTint = .neutral,
        liquidGlassFluidPulse: Bool = true,
        liquidGlassCustomOpacity: CGFloat = 0.0,
        liquidGlassCustomBlur: CGFloat = 0.0,
        liquidGlassRimShine: CGFloat = 0.0
    ) {
        self.id = id
        self.name = name
        self.layout = layout
        self.flipHorizontal = flipHorizontal
        self.horizontalAlign = horizontalAlign
        self.verticalAlign = verticalAlign
        self.containerWidth = containerWidth
        self.artworkSize = artworkSize
        self.cornerRadius = cornerRadius
        self.artworkShadow = artworkShadow
        self.lightingEffect = lightingEffect
        self.showSpinningRecord = showSpinningRecord
        self.shelfFinish = shelfFinish
        self.backdropMaterial = backdropMaterial
        self.backdropCornerRadius = backdropCornerRadius
        self.showPlaybackControls = showPlaybackControls
        self.controlsPlacement = controlsPlacement
        self.controlsSize = controlsSize
        self.showLikeControl = showLikeControl
        self.showProgressBar = showProgressBar
        self.trackNameStyle = trackNameStyle
        self.artistStyle = artistStyle
        self.albumStyle = albumStyle
        self.windowPlacement = windowPlacement
        self.floatOnTrackChange = floatOnTrackChange
        self.liquidGlassLevel = liquidGlassLevel
        self.liquidGlassTint = liquidGlassTint
        self.liquidGlassFluidPulse = liquidGlassFluidPulse
        self.liquidGlassCustomOpacity = liquidGlassCustomOpacity
        self.liquidGlassCustomBlur = liquidGlassCustomBlur
        self.liquidGlassRimShine = liquidGlassRimShine
    }

    enum CodingKeys: String, CodingKey {
        case id, name, layout, flipHorizontal, horizontalAlign, verticalAlign, containerWidth
        case artworkSize, cornerRadius, artworkShadow, lightingEffect, showSpinningRecord, shelfFinish
        case backdropMaterial, backdropCornerRadius, showPlaybackControls, controlsPlacement, controlsSize, showLikeControl, showProgressBar
        case trackNameStyle, artistStyle, albumStyle, windowPlacement, floatOnTrackChange
        case liquidGlassLevel, liquidGlassTint, liquidGlassFluidPulse, liquidGlassCustomOpacity, liquidGlassCustomBlur, liquidGlassRimShine
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Custom Theme"
        self.layout = try container.decodeIfPresent(SleeveLayout.self, forKey: .layout) ?? .horizontal
        self.flipHorizontal = try container.decodeIfPresent(Bool.self, forKey: .flipHorizontal) ?? false
        self.horizontalAlign = try container.decodeIfPresent(HorizontalAlign.self, forKey: .horizontalAlign) ?? .left
        self.verticalAlign = try container.decodeIfPresent(VerticalAlign.self, forKey: .verticalAlign) ?? .middle
        self.containerWidth = try container.decodeIfPresent(CGFloat.self, forKey: .containerWidth) ?? 200
        self.artworkSize = try container.decodeIfPresent(CGFloat.self, forKey: .artworkSize) ?? 140
        self.cornerRadius = try container.decodeIfPresent(CGFloat.self, forKey: .cornerRadius) ?? 12
        self.artworkShadow = try container.decodeIfPresent(ShadowStyle.self, forKey: .artworkShadow) ?? .regular
        self.lightingEffect = try container.decodeIfPresent(LightingEffect.self, forKey: .lightingEffect) ?? .spotlight
        self.showSpinningRecord = try container.decodeIfPresent(Bool.self, forKey: .showSpinningRecord) ?? false
        self.shelfFinish = try container.decodeIfPresent(ShelfFinish.self, forKey: .shelfFinish) ?? .darkWalnut
        self.backdropMaterial = try container.decodeIfPresent(BackdropMaterial.self, forKey: .backdropMaterial) ?? .glass
        self.backdropCornerRadius = try container.decodeIfPresent(CGFloat.self, forKey: .backdropCornerRadius) ?? 20
        self.showPlaybackControls = try container.decodeIfPresent(Bool.self, forKey: .showPlaybackControls) ?? true
        self.controlsPlacement = try container.decodeIfPresent(ControlsPlacement.self, forKey: .controlsPlacement) ?? .onHover
        self.controlsSize = try container.decodeIfPresent(ControlsSize.self, forKey: .controlsSize) ?? .medium
        self.showLikeControl = try container.decodeIfPresent(Bool.self, forKey: .showLikeControl) ?? true
        self.showProgressBar = try container.decodeIfPresent(Bool.self, forKey: .showProgressBar) ?? true
        self.trackNameStyle = try container.decodeIfPresent(TypographyLineConfig.self, forKey: .trackNameStyle) ?? TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .bold, fontSize: 15, isWhiteText: true, shadow: .subtle)
        self.artistStyle = try container.decodeIfPresent(TypographyLineConfig.self, forKey: .artistStyle) ?? TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .medium, fontSize: 13, isWhiteText: true, shadow: .subtle)
        self.albumStyle = try container.decodeIfPresent(TypographyLineConfig.self, forKey: .albumStyle) ?? TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .regular, fontSize: 12, isWhiteText: true, shadow: .none)
        self.windowPlacement = try container.decodeIfPresent(WindowLevelPlacement.self, forKey: .windowPlacement) ?? .desktop
        self.floatOnTrackChange = try container.decodeIfPresent(Bool.self, forKey: .floatOnTrackChange) ?? false

        self.liquidGlassLevel = try container.decodeIfPresent(LiquidGlassLevel.self, forKey: .liquidGlassLevel) ?? .system
        self.liquidGlassTint = try container.decodeIfPresent(LiquidGlassTint.self, forKey: .liquidGlassTint) ?? .neutral
        self.liquidGlassFluidPulse = try container.decodeIfPresent(Bool.self, forKey: .liquidGlassFluidPulse) ?? true
        self.liquidGlassCustomOpacity = try container.decodeIfPresent(CGFloat.self, forKey: .liquidGlassCustomOpacity) ?? 0.0
        self.liquidGlassCustomBlur = try container.decodeIfPresent(CGFloat.self, forKey: .liquidGlassCustomBlur) ?? 0.0
        self.liquidGlassRimShine = try container.decodeIfPresent(CGFloat.self, forKey: .liquidGlassRimShine) ?? 0.0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(layout, forKey: .layout)
        try container.encode(flipHorizontal, forKey: .flipHorizontal)
        try container.encode(horizontalAlign, forKey: .horizontalAlign)
        try container.encode(verticalAlign, forKey: .verticalAlign)
        try container.encode(containerWidth, forKey: .containerWidth)
        try container.encode(artworkSize, forKey: .artworkSize)
        try container.encode(cornerRadius, forKey: .cornerRadius)
        try container.encode(artworkShadow, forKey: .artworkShadow)
        try container.encode(lightingEffect, forKey: .lightingEffect)
        try container.encode(showSpinningRecord, forKey: .showSpinningRecord)
        try container.encode(shelfFinish, forKey: .shelfFinish)
        try container.encode(backdropMaterial, forKey: .backdropMaterial)
        try container.encode(backdropCornerRadius, forKey: .backdropCornerRadius)
        try container.encode(showPlaybackControls, forKey: .showPlaybackControls)
        try container.encode(controlsPlacement, forKey: .controlsPlacement)
        try container.encode(controlsSize, forKey: .controlsSize)
        try container.encode(showLikeControl, forKey: .showLikeControl)
        try container.encode(showProgressBar, forKey: .showProgressBar)
        try container.encode(trackNameStyle, forKey: .trackNameStyle)
        try container.encode(artistStyle, forKey: .artistStyle)
        try container.encode(albumStyle, forKey: .albumStyle)
        try container.encode(windowPlacement, forKey: .windowPlacement)
        try container.encode(floatOnTrackChange, forKey: .floatOnTrackChange)
        try container.encode(liquidGlassLevel, forKey: .liquidGlassLevel)
        try container.encode(liquidGlassTint, forKey: .liquidGlassTint)
        try container.encode(liquidGlassFluidPulse, forKey: .liquidGlassFluidPulse)
        try container.encode(liquidGlassCustomOpacity, forKey: .liquidGlassCustomOpacity)
        try container.encode(liquidGlassCustomBlur, forKey: .liquidGlassCustomBlur)
        try container.encode(liquidGlassRimShine, forKey: .liquidGlassRimShine)
    }

    // MARK: - Built-in Presets Matching Sleeve 3 & Sleeve 3.3

    public static let presetStack = SleeveThemeConfig(
        id: "preset-stack",
        name: "Stack",
        layout: .stacked,
        flipHorizontal: false,
        horizontalAlign: .center,
        verticalAlign: .middle,
        containerWidth: 220,
        artworkSize: 180,
        cornerRadius: 18,
        artworkShadow: .regular,
        lightingEffect: .glare,
        showSpinningRecord: false,
        shelfFinish: .darkWalnut,
        backdropMaterial: .liquidGlass,
        backdropCornerRadius: 24,
        showPlaybackControls: true,
        controlsPlacement: .onHover,
        controlsSize: .medium,
        showLikeControl: true,
        showProgressBar: true,
        trackNameStyle: TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .bold, fontSize: 15, isWhiteText: true, shadow: .subtle),
        artistStyle: TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .medium, fontSize: 13, isWhiteText: true, shadow: .subtle),
        albumStyle: TypographyLineConfig(isVisible: false, fontDesign: .sans, fontWeight: .regular, fontSize: 11, isWhiteText: false, shadow: .none),
        windowPlacement: .desktop,
        liquidGlassLevel: .system,
        liquidGlassTint: .albumArt,
        liquidGlassFluidPulse: true
    )

    public static let presetHorizontalCard = SleeveThemeConfig(
        id: "preset-horizontal-card",
        name: "Ider",
        layout: .horizontal,
        flipHorizontal: false,
        horizontalAlign: .left,
        verticalAlign: .middle,
        containerWidth: 230,
        artworkSize: 130,
        cornerRadius: 14,
        artworkShadow: .subtle,
        lightingEffect: .spotlight,
        showSpinningRecord: false,
        shelfFinish: .darkWalnut,
        backdropMaterial: .blur,
        backdropCornerRadius: 20,
        showPlaybackControls: true,
        controlsPlacement: .inlineWithText,
        controlsSize: .small,
        showLikeControl: true,
        showProgressBar: true,
        trackNameStyle: TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .bold, fontSize: 16, isWhiteText: true, shadow: .subtle),
        artistStyle: TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .semibold, fontSize: 13, isWhiteText: true, shadow: .subtle),
        albumStyle: TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .regular, fontSize: 12, isWhiteText: true, shadow: .none),
        windowPlacement: .desktop
    )

    public static let presetColeSerif = SleeveThemeConfig(
        id: "preset-cole",
        name: "Cole",
        layout: .vertical,
        flipHorizontal: false,
        horizontalAlign: .center,
        verticalAlign: .middle,
        containerWidth: 200,
        artworkSize: 160,
        cornerRadius: 8,
        artworkShadow: .deep,
        lightingEffect: .none,
        showSpinningRecord: false,
        shelfFinish: .lightOak,
        backdropMaterial: .solid,
        backdropCornerRadius: 16,
        showPlaybackControls: true,
        controlsPlacement: .inlineWithText,
        controlsSize: .medium,
        showLikeControl: true,
        showProgressBar: false,
        trackNameStyle: TypographyLineConfig(isVisible: true, fontDesign: .serif, fontWeight: .bold, fontSize: 17, isWhiteText: true, shadow: .none),
        artistStyle: TypographyLineConfig(isVisible: true, fontDesign: .serif, fontWeight: .medium, fontSize: 14, isWhiteText: true, shadow: .none),
        albumStyle: TypographyLineConfig(isVisible: true, fontDesign: .serif, fontWeight: .regular, fontSize: 12, isWhiteText: true, shadow: .none),
        windowPlacement: .desktop
    )

    public static let presetMinimal = SleeveThemeConfig(
        id: "preset-minimal",
        name: "Minimal",
        layout: .textOnly,
        flipHorizontal: false,
        horizontalAlign: .left,
        verticalAlign: .middle,
        containerWidth: 240,
        artworkSize: 0,
        cornerRadius: 0,
        artworkShadow: .none,
        lightingEffect: .none,
        showSpinningRecord: false,
        shelfFinish: .matteBlack,
        backdropMaterial: .clear,
        backdropCornerRadius: 8,
        showPlaybackControls: true,
        controlsPlacement: .inlineWithText,
        controlsSize: .small,
        showLikeControl: false,
        showProgressBar: false,
        trackNameStyle: TypographyLineConfig(isVisible: true, fontDesign: .mono, fontWeight: .bold, fontSize: 14, isWhiteText: true, shadow: .subtle),
        artistStyle: TypographyLineConfig(isVisible: true, fontDesign: .mono, fontWeight: .regular, fontSize: 12, isWhiteText: true, shadow: .subtle),
        albumStyle: TypographyLineConfig(isVisible: false, fontDesign: .mono, fontWeight: .regular, fontSize: 11, isWhiteText: false, shadow: .none),
        windowPlacement: .desktop
    )

    public static let presetRetroVinyl = SleeveThemeConfig(
        id: "preset-retro-vinyl",
        name: "Retro Vinyl",
        layout: .vintageVinyl,
        flipHorizontal: false,
        horizontalAlign: .left,
        verticalAlign: .middle,
        containerWidth: 260,
        artworkSize: 150,
        cornerRadius: 4,
        artworkShadow: .regular,
        lightingEffect: .spotlight,
        showSpinningRecord: true,
        shelfFinish: .darkWalnut,
        backdropMaterial: .clear,
        backdropCornerRadius: 16,
        showPlaybackControls: true,
        controlsPlacement: .onHover,
        controlsSize: .medium,
        showLikeControl: true,
        showProgressBar: true,
        trackNameStyle: TypographyLineConfig(isVisible: true, fontDesign: .round, fontWeight: .bold, fontSize: 15, isWhiteText: true, shadow: .subtle),
        artistStyle: TypographyLineConfig(isVisible: true, fontDesign: .round, fontWeight: .medium, fontSize: 13, isWhiteText: true, shadow: .subtle),
        albumStyle: TypographyLineConfig(isVisible: true, fontDesign: .round, fontWeight: .regular, fontSize: 11, isWhiteText: true, shadow: .none),
        windowPlacement: .desktop
    )

    public static let presetWoodenShelf = SleeveThemeConfig(
        id: "preset-wooden-shelf",
        name: "Wooden Shelf",
        layout: .woodenShelf,
        flipHorizontal: false,
        horizontalAlign: .left,
        verticalAlign: .middle,
        containerWidth: 240,
        artworkSize: 140,
        cornerRadius: 6,
        artworkShadow: .deep,
        lightingEffect: .spotlight,
        showSpinningRecord: false,
        shelfFinish: .lightOak,
        backdropMaterial: .clear,
        backdropCornerRadius: 16,
        showPlaybackControls: true,
        controlsPlacement: .inlineWithText,
        controlsSize: .medium,
        showLikeControl: true,
        showProgressBar: true,
        trackNameStyle: TypographyLineConfig(isVisible: true, fontDesign: .serif, fontWeight: .bold, fontSize: 16, isWhiteText: true, shadow: .subtle),
        artistStyle: TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .medium, fontSize: 13, isWhiteText: true, shadow: .subtle),
        albumStyle: TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .regular, fontSize: 12, isWhiteText: true, shadow: .none),
        windowPlacement: .desktop
    )

    public static let allPresets: [SleeveThemeConfig] = [
        .presetStack,
        .presetHorizontalCard,
        .presetColeSerif,
        .presetMinimal,
        .presetRetroVinyl,
        .presetWoodenShelf
    ]
}
