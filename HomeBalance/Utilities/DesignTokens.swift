import SwiftUI

// MARK: - Design System: "The Financial Curator"
//
// Color tokens, typography presets, corner radii, and shadow styles extracted
// from the Google Stitch design package (estate_financial/DESIGN.md).
//
// Color tokens are declared on `ShapeStyle where Self == Color` (the same
// pattern Apple uses for `.red`, `.blue`, etc.) so they can be used with
// dot-shorthand in `.foregroundStyle(...)`, `.tint(...)`, and `.background(...)`.

// MARK: - Color Tokens

extension ShapeStyle where Self == Color {

    // Primary palette
    /// Main brand blue — #0058bc
    static var hbPrimary: Color         { Color(hex: "#0058bc") }
    /// Lighter blue accent — #3b78cf
    static var hbPrimaryDim: Color      { Color(hex: "#3b78cf") }
    /// Very light blue tint — #d6e4ff
    static var hbPrimaryContainer: Color { Color(hex: "#d6e4ff") }

    // Secondary palette (income / progress bars)
    /// Deep green — #006e28
    static var hbSecondary: Color       { Color(hex: "#006e28") }
    /// Light green tint — #96f7a4
    static var hbSecondaryContainer: Color { Color(hex: "#96f7a4") }

    // Error / expense
    /// Error red — #ba1a1a
    static var hbError: Color           { Color(hex: "#ba1a1a") }
    /// Light error tint — #ffdad6
    static var hbErrorContainer: Color  { Color(hex: "#ffdad6") }

    // Surface / background
    /// Page background — #faf9fe
    static var hbSurface: Color         { Color(hex: "#faf9fe") }
    /// Card inset / secondary bg — #f4f3f8
    static var hbSurfaceLow: Color      { Color(hex: "#f4f3f8") }
    /// Dividers / inactive — #e1e2ec
    static var hbSurfaceVariant: Color  { Color(hex: "#e1e2ec") }

    // Text
    /// Primary text — #1a1b1f
    static var hbOnSurface: Color       { Color(hex: "#1a1b1f") }
    /// Secondary text — #44464f
    static var hbOnSurfaceVariant: Color { Color(hex: "#44464f") }

    // Accent
    /// Orange/amber accent — #c07000
    static var hbTertiary: Color        { Color(hex: "#c07000") }

    // Semantic aliases
    /// Income positive — same as hbSecondary
    static var hbPositive: Color        { Color(hex: "#006e28") }
    /// Expense negative — same as hbError
    static var hbNegative: Color        { Color(hex: "#ba1a1a") }
}

// MARK: - Explicit Color namespace helpers
//
// Allows `Color.hbPrimary` as well as `.hbPrimary` in ShapeStyle contexts.

extension Color {
    static let hbPrimary          = Color(hex: "#0058bc")
    static let hbPrimaryDim       = Color(hex: "#3b78cf")
    static let hbPrimaryContainer = Color(hex: "#d6e4ff")
    static let hbSecondary        = Color(hex: "#006e28")
    static let hbSecondaryContainer = Color(hex: "#96f7a4")
    static let hbError            = Color(hex: "#ba1a1a")
    static let hbErrorContainer   = Color(hex: "#ffdad6")
    static let hbSurface          = Color(hex: "#faf9fe")
    static let hbSurfaceLow       = Color(hex: "#f4f3f8")
    static let hbSurfaceVariant   = Color(hex: "#e1e2ec")
    static let hbOnSurface        = Color(hex: "#1a1b1f")
    static let hbOnSurfaceVariant = Color(hex: "#44464f")
    static let hbTertiary         = Color(hex: "#c07000")
    static let hbPositive         = Color(hex: "#006e28")
    static let hbNegative         = Color(hex: "#ba1a1a")
}

// MARK: - Gradient

extension LinearGradient {
    /// Primary button gradient: hbPrimary → hbPrimaryDim at 135°
    static let hbPrimaryGradient = LinearGradient(
        colors: [.hbPrimary, .hbPrimaryDim],
        startPoint: UnitPoint(x: 0.15, y: 0),
        endPoint: UnitPoint(x: 0.85, y: 1)
    )
}

// MARK: - Typography Scale

extension Font {
    /// Display medium: 2.25rem / 36 pt — hero balance figures on summary card
    static let hbDisplayMedium  = Font.system(size: 36, weight: .bold, design: .rounded)

    /// Headline large: 1.75rem / 28 pt — section titles
    static let hbHeadlineLarge  = Font.system(size: 28, weight: .semibold)

    /// Headline medium: 1.25rem / 20 pt — card subtitles / nav month label
    static let hbHeadlineMedium = Font.system(size: 20, weight: .semibold)

    /// Label large: 0.875rem / 14 pt — metric labels, small caps
    static let hbLabelLarge     = Font.system(size: 14, weight: .medium)

    /// Label small: 0.75rem / 12 pt — captions / badges
    static let hbLabelSmall     = Font.system(size: 12, weight: .medium)
}

// MARK: - Corner Radius

enum HBRadius {
    /// Card / sheet radius — 24 pt (1.5 rem)
    static let card: CGFloat = 24
    /// Button / pill radius — effectively circular
    static let button: CGFloat = 9999
    /// Chip / small badge
    static let chip: CGFloat = 12
    /// Progress bar end cap
    static let progressBar: CGFloat = 4
}

// MARK: - Shadows

struct HBShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    /// Ambient / floating card shadow (24 px blur, 4 % opacity)
    static let card   = HBShadow(color: .black.opacity(0.04), radius: 24, x: 0, y: 4)
    /// Subtle inset lift
    static let subtle = HBShadow(color: .black.opacity(0.06), radius: 8,  x: 0, y: 2)
}

extension View {
    func hbCardShadow() -> some View {
        shadow(
            color: HBShadow.card.color,
            radius: HBShadow.card.radius,
            x: HBShadow.card.x,
            y: HBShadow.card.y
        )
    }

    func hbSubtleShadow() -> some View {
        shadow(
            color: HBShadow.subtle.color,
            radius: HBShadow.subtle.radius,
            x: HBShadow.subtle.x,
            y: HBShadow.subtle.y
        )
    }

    /// Standard card style: white background, 24 pt corners, ambient shadow.
    func hbCard() -> some View {
        self
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: HBRadius.card))
            .hbCardShadow()
    }

    /// Surface-low card: slightly tinted background, 24 pt corners.
    func hbSurfaceCard() -> some View {
        self
            .background(Color.hbSurfaceLow)
            .clipShape(RoundedRectangle(cornerRadius: HBRadius.card))
    }
}

// MARK: - Spacing

enum HBSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}
