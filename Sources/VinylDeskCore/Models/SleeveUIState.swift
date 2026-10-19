import SwiftUI

@MainActor
public final class ArtworkState: ObservableObject {
    @Published public var rotationAngle: Double = 0
    public init() {}
}

@MainActor
public final class SleeveControlsState: ObservableObject {
    @Published public var isLiked: Bool = false
    public init() {}
}

@MainActor
public final class WidgetHoverState: ObservableObject {
    @Published public var isHovered: Bool = false
    public init() {}
}

@MainActor
public final class TypographyInspectorState: ObservableObject {
    @Published public var selectedTarget: TypographyTarget = .trackName
    public init() {}
}

@MainActor
public final class ThemesInspectorState: ObservableObject {
    @Published public var showExportAlert: Bool = false
    @Published public var exportedJSON: String = ""
    @Published public var showSaveCustomModal: Bool = false
    @Published public var newThemeName: String = ""
    public init() {}
}

@MainActor
public final class PreferencesWindowState: ObservableObject {
    @Published public var selectedTab: PreferencesTab = .layout
    @Published public var searchText: String = ""
    @Published public var previewIsLightMode: Bool = false
    @Published public var showLivePreview: Bool = true
    public init() {}
}

@MainActor
public final class LiquidShimmerState: ObservableObject {
    @Published public var shimmerPhase: CGFloat = 0.0
    public init() {}
}

@MainActor
public final class FittedWidgetState: ObservableObject {
    @Published public var measuredWidth: CGFloat = 0.0
    @Published public var measuredHeight: CGFloat = 0.0
    public init() {}
}

