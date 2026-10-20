import SwiftUI

public struct LayoutInspectorView: View {
    @ObservedObject var themeManager: VinylThemeManager

    @MainActor
    public init(themeManager: VinylThemeManager) {
        self.themeManager = themeManager
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VinylAlignmentCard(themeManager: themeManager)
            }
            .padding(16)
        }
    }
}
