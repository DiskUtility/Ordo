import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.17, green: 0.40, blue: 0.79)
    static let warning = Color(red: 0.84, green: 0.36, blue: 0.17)
    static let success = Color(red: 0.16, green: 0.55, blue: 0.27)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let screenBackground = Color(.systemGroupedBackground)
    static let cardCornerRadius: CGFloat = 22
    static let cardPadding: CGFloat = 14
    static let screenPadding: CGFloat = 14
    static let cardBorder = Color.black.opacity(0.06)
}

extension View {
    func plannerCard() -> some View {
        self
            .padding(12)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func plannerSurfaceCard(
        padding: CGFloat = AppTheme.cardPadding,
        cornerRadius: CGFloat = AppTheme.cardCornerRadius
    ) -> some View {
        self
            .padding(padding)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
    }

    func plannerSectionTitle() -> some View {
        self
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(.primary)
    }
}
