import SwiftUI
import AppKit

// MARK: - Spacing

/// 4pt baseline grid used across the redesign.
/// All paddings/gaps must reuse one of these constants — no magic numbers.
enum LCSpacing {
    static let xxs: CGFloat = 4
    static let xs:  CGFloat = 8
    static let sm:  CGFloat = 12
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 20
    static let xl:  CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Radius

enum LCRadius {
    static let chip:   CGFloat = 8
    static let button: CGFloat = 12
    static let card:   CGFloat = 16
    static let panel:  CGFloat = 20
    static let modal:  CGFloat = 24
    static let pill:   CGFloat = 999
}

// MARK: - Elevation

enum LCElevation: Int {
    case base = 0       // popover root
    case card = 1       // cards over the popover
    case control = 2    // buttons / chips
    case overlay = 3    // modal / onboarding
}

// MARK: - Typography

/// All font sizes used by the redesign — SF Pro Text exclusively.
/// Use these instead of inline `.font(.system(size: ...))` calls to keep
/// vertical rhythm consistent.
enum LCTypo {
    static func display() -> Font {
        .system(size: 22, weight: .bold, design: .default)
    }
    static func title() -> Font {
        .system(size: 17, weight: .semibold, design: .default)
    }
    static func subtitle() -> Font {
        .system(size: 15, weight: .semibold, design: .default)
    }
    static func body() -> Font {
        .system(size: 13, weight: .regular, design: .default)
    }
    static func bodyMedium() -> Font {
        .system(size: 13, weight: .medium, design: .default)
    }
    static func bodySemibold() -> Font {
        .system(size: 13, weight: .semibold, design: .default)
    }
    static func caption() -> Font {
        .system(size: 12, weight: .medium, design: .default)
    }
    static func micro() -> Font {
        .system(size: 11, weight: .medium, design: .default)
    }
    static func microSemibold() -> Font {
        .system(size: 11, weight: .semibold, design: .default)
    }
    static func sectionHeader() -> Font {
        .system(size: 11, weight: .bold, design: .default)
    }
}

// MARK: - Animation

enum LCAnimation {
    /// Default for layout / size / opacity changes that affect anything bigger than a button.
    static let standard: Animation = .spring(response: 0.45, dampingFraction: 0.78)
    /// Micro-interactions: hover, press, tab indicator.
    static let micro:    Animation = .spring(response: 0.25, dampingFraction: 0.85)
    /// Sharp, snappy spring for toggle state changes.
    static let snap:     Animation = .spring(response: 0.30, dampingFraction: 0.88)
    /// Plain fade.
    static let fade:     Animation = .easeOut(duration: 0.20)
}

// MARK: - Palette (semantic)

enum LCPalette {
    static var ink:        Color { Color.primary }
    static var muted:      Color { Color.secondary }
    static var accent:     Color { Color(nsColor: .controlAccentColor) }
    static var separator:  Color { Color(nsColor: .separatorColor).opacity(0.40) }
    static var success:    Color { Color.green.opacity(0.80) }
    static var warning:    Color { Color.orange.opacity(0.85) }
    static var danger:     Color { Color.red.opacity(0.80) }

    // Glass strokes
    static var strokeHi:   Color { Color.white.opacity(0.30) }
    static var strokeMid:  Color { Color.white.opacity(0.12) }
    static var strokeLo:   Color { Color.white.opacity(0.05) }

    // Highlights
    static var highlight:  Color { Color.white.opacity(0.12) }
}

// MARK: - Background

/// The popover backdrop. Two layered gradients + a `.regularMaterial` rectangle
/// give the "quiet glass" sensation: soft chromatic warmth at the top, a
/// neutral neutral mid, and a subtle accent halo bottom-trailing.
struct LCBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor).opacity(0.96),
                    Color(nsColor: .controlBackgroundColor).opacity(0.92),
                    Color(nsColor: .underPageBackgroundColor).opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft accent halo
            RadialGradient(
                colors: [
                    Color(nsColor: .controlAccentColor).opacity(0.16),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 4,
                endRadius: 320
            )
            .blendMode(.plusLighter)
            .opacity(0.6)

            // Specular highlight band
            LinearGradient(
                colors: [
                    Color.white.opacity(0.10),
                    Color.clear,
                    Color.black.opacity(0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            Rectangle().fill(.regularMaterial).opacity(0.45)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Card / Chip / Button modifiers

/// Card surface — Level 1 elevation. Use on lamp rows, settings groups, etc.
private struct LCCardModifier: ViewModifier {
    var radius: CGFloat = LCRadius.card
    var tint: Color? = nil

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if #available(macOS 26.0, *) {
            if let tint {
                content
                    .glassEffect(.regular.tint(tint.opacity(0.30)), in: shape)
                    .overlay(strokeOverlay(radius: radius))
                    .contentShape(shape)
            } else {
                content
                    .glassEffect(.regular, in: shape)
                    .overlay(strokeOverlay(radius: radius))
                    .contentShape(shape)
            }
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .background(
                    (tint ?? Color.white.opacity(0.04))
                        .opacity(0.55),
                    in: shape
                )
                .overlay(specularOverlay(radius: radius))
                .overlay(strokeOverlay(radius: radius))
                .contentShape(shape)
        }
    }

    private func strokeOverlay(radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [LCPalette.strokeHi, LCPalette.strokeMid, LCPalette.strokeLo],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
            .allowsHitTesting(false)
    }

    private func specularOverlay(radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.12), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .allowsHitTesting(false)
    }
}

/// Chip surface — pill-shaped Level 2 element. For tags / inline pills.
private struct LCChipModifier: ViewModifier {
    var tint: Color? = nil

    func body(content: Content) -> some View {
        let shape = Capsule(style: .continuous)
        if #available(macOS 26.0, *) {
            if let tint {
                content
                    .glassEffect(.regular.tint(tint), in: shape)
                    .contentShape(shape)
            } else {
                content
                    .glassEffect(.regular, in: shape)
                    .contentShape(shape)
            }
        } else {
            content
                .background(.thinMaterial, in: shape)
                .background((tint ?? Color.white.opacity(0.06)).opacity(0.70), in: shape)
                .overlay(
                    shape.strokeBorder(LCPalette.strokeMid, lineWidth: 0.5)
                )
                .contentShape(shape)
        }
    }
}

/// Hoverable wrapper: scale 1.02 + tinted glow on hover.
struct LCHoverable: ViewModifier {
    @State private var isHovering = false
    var glowTint: Color = LCPalette.accent
    var radius: CGFloat = LCRadius.card

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(glowTint.opacity(isHovering ? 0.45 : 0), lineWidth: 1)
                    .blur(radius: isHovering ? 0.8 : 0)
                    .allowsHitTesting(false)
            )
            .animation(LCAnimation.micro, value: isHovering)
            .onHover { hovering in isHovering = hovering }
    }
}

/// Press wrapper for plain Buttons — scale 0.97 while pressed.
struct LCPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(LCAnimation.micro, value: configuration.isPressed)
    }
}

// MARK: - Glass Button Style (Quiet Glass)

/// Prominent / regular glass button. Pairs a glass surface with the press
/// micro-interaction and a hoverable highlight ring.
struct LCGlassButtonStyle: ButtonStyle {
    var prominent: Bool = false
    var radius: CGFloat = LCRadius.button

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(LCCardModifier(
                radius: radius,
                tint: prominent ? LCPalette.accent.opacity(0.45) : Color.white.opacity(0.06)
            ))
            .modifier(LCHoverable(glowTint: prominent ? LCPalette.accent : Color.white, radius: radius))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(LCAnimation.micro, value: configuration.isPressed)
    }
}

// MARK: - View extensions

extension View {
    /// Apply the Quiet Glass card surface (Level 1).
    func lcCard(radius: CGFloat = LCRadius.card, tint: Color? = nil) -> some View {
        modifier(LCCardModifier(radius: radius, tint: tint))
    }

    /// Apply a pill-shaped chip surface.
    func lcChip(tint: Color? = nil) -> some View {
        modifier(LCChipModifier(tint: tint))
    }

    /// Apply hoverable feedback: scale + glow.
    func lcHoverable(glowTint: Color = LCPalette.accent, radius: CGFloat = LCRadius.card) -> some View {
        modifier(LCHoverable(glowTint: glowTint, radius: radius))
    }

    /// Wrap children in a glass-effect container on macOS 26+, otherwise pass-through.
    @ViewBuilder
    func lcGlassGroup(spacing: CGFloat = LCSpacing.sm) -> some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { self }
        } else {
            self
        }
    }

    /// Soft shadow used by overlays (Level 3 elevation).
    func lcOverlayShadow() -> some View {
        shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 8)
    }

    /// Convenience for letter-spaced large titles.
    func lcTrackedTitle() -> some View {
        kerning(-0.2)
    }
}

// MARK: - Symbol effect helpers (macOS 14+ guard)

/// Apply a "bounce" symbol effect when supported (macOS 14+).
/// On macOS 13 this is a no-op.
struct LCBounceSymbol<V: Equatable>: ViewModifier {
    let value: V
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content.symbolEffect(.bounce, value: value)
        } else {
            content
        }
    }
}

/// Apply a pulsing symbol effect when supported (macOS 14+).
struct LCPulseSymbol: ViewModifier {
    let isActive: Bool
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content.symbolEffect(.pulse, isActive: isActive)
        } else {
            content.opacity(isActive ? 0.65 : 1.0)
                .animation(isActive ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                           value: isActive)
        }
    }
}

extension View {
    func lcBounceSymbol<V: Equatable>(value: V) -> some View {
        modifier(LCBounceSymbol(value: value))
    }
    func lcPulseSymbol(active: Bool) -> some View {
        modifier(LCPulseSymbol(isActive: active))
    }
}

// MARK: - Reusable mini components

/// Iconic circle badge — used in headers and empty states.
struct LCIconBadge: View {
    let systemName: String
    var size: CGFloat = 36
    var tint: Color = LCPalette.accent
    var fontSize: CGFloat = 16

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .lcCard(radius: size / 2, tint: tint.opacity(0.18))
    }
}

/// Small pulsing status dot.
struct LCStatusDot: View {
    var color: Color = LCPalette.accent
    var animated: Bool = false

    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.85)).frame(width: 6, height: 6)
            if animated {
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 6, height: 6)
                    .scaleEffect(2.4)
                    .opacity(0)
                    .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: animated)
            }
        }
        .frame(width: 12, height: 12)
    }
}

/// Section header used by Lamps room groups & Settings groups.
struct LCSectionHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(LCTypo.sectionHeader())
            .tracking(0.5)
            .foregroundStyle(LCPalette.muted)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, LCSpacing.xs)
            .padding(.horizontal, LCSpacing.xs)
    }
}

/// Empty-state card used by Lamps view, Onboarding, etc.
struct LCEmptyState: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    var cta: LocalizedStringKey? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: LCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(LCPalette.muted)
                .frame(width: 56, height: 56)
                .lcCard(radius: 28, tint: LCPalette.accent.opacity(0.10))

            Text(title)
                .font(LCTypo.subtitle())
                .foregroundStyle(LCPalette.ink)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(LCTypo.caption())
                .foregroundStyle(LCPalette.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let cta, let action {
                Button(action: action) {
                    Text(cta)
                        .font(LCTypo.bodySemibold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(LCGlassButtonStyle(prominent: true, radius: LCRadius.button))
                .padding(.top, LCSpacing.xs)
            }
        }
        .padding(LCSpacing.lg)
        .frame(maxWidth: .infinity)
        .lcCard(radius: LCRadius.panel)
    }
}

// MARK: - Custom brightness slider

/// Quiet-glass slider with a glowing fill proportional to the value.
struct LCBrightnessSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double = 1
    var icon: String = "sun.max.fill"
    var tint: Color = Color(red: 0.96, green: 0.77, blue: 0.26)
    var onCommit: ((Double) -> Void)? = nil

    @State private var isDragging = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let progress = CGFloat((value - range.lowerBound) / max(0.0001, (range.upperBound - range.lowerBound)))
            let fillWidth = max(20, min(width, width * progress))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.ultraThinMaterial)
                Capsule()
                    .strokeBorder(LCPalette.strokeMid, lineWidth: 0.5)

                // Filled tint with halo proportional to value
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.55), tint.opacity(0.90)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth)
                    .shadow(color: tint.opacity(0.35 + 0.35 * progress), radius: 8 * progress + 2, y: 0)

                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.leading, 10)
                    Spacer()
                    Text("\(Int(round(progress * 100)))%")
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.trailing, 10)
                }
            }
            .frame(height: 28)
            .contentShape(Capsule())
            .scaleEffect(isDragging ? 1.02 : 1.0)
            .animation(LCAnimation.micro, value: isDragging)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        isDragging = true
                        let raw = Double(drag.location.x / max(1, width))
                        let clamped = min(max(0, raw), 1)
                        let newValue = range.lowerBound + clamped * (range.upperBound - range.lowerBound)
                        let stepped = (newValue / step).rounded() * step
                        value = min(max(range.lowerBound, stepped), range.upperBound)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onCommit?(value)
                    }
            )
        }
        .frame(height: 28)
    }
}
