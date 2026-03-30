import SwiftUI

/// Generic empty-state illustration used across list screens.
/// Design: "The Financial Curator" — subtle icon, primary-blue CTA button.
struct EmptyStateView: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    init(
        icon: String,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: HBSpacing.md) {
            // Tinted icon circle
            ZStack {
                Circle()
                    .fill(Color.hbPrimaryContainer)
                    .frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(.system(size: 38))
                    .foregroundStyle(.hbPrimary)
            }
            .padding(.bottom, HBSpacing.xs)

            Text(title)
                .font(.hbHeadlineMedium)
                .foregroundStyle(.hbOnSurface)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.hbOnSurfaceVariant)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.hbLabelLarge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, HBSpacing.xl)
                        .padding(.vertical, HBSpacing.sm + 2)
                        .background(LinearGradient.hbPrimaryGradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, HBSpacing.xs)
            }
        }
        .padding(HBSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "tray",
        title: "No Transactions",
        subtitle: "Add your first transaction to get started.",
        actionTitle: "Add Transaction"
    ) {}
}
