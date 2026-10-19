import SwiftUI

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

public enum BackdropMaterial: String, CaseIterable, Codable, Sendable {
    case blur = "Blur"
    case glass = "Glass"
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
        floatOnTrackChange: Bool = false
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
        backdropMaterial: .glass,
        backdropCornerRadius: 24,
        showPlaybackControls: true,
        controlsPlacement: .onHover,
        controlsSize: .medium,
        showLikeControl: true,
        showProgressBar: true,
        trackNameStyle: TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .bold, fontSize: 15, isWhiteText: true, shadow: .subtle),
        artistStyle: TypographyLineConfig(isVisible: true, fontDesign: .sans, fontWeight: .medium, fontSize: 13, isWhiteText: true, shadow: .subtle),
        albumStyle: TypographyLineConfig(isVisible: false, fontDesign: .sans, fontWeight: .regular, fontSize: 11, isWhiteText: false, shadow: .none),
        windowPlacement: .desktop
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
