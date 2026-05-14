import SwiftUI

struct ControlCenterView: View {
    @EnvironmentObject private var appState: AppState
    @Namespace private var tabNamespace

    var body: some View {
        ZStack {
            LCBackdrop()

            content
                .lcGlassGroup(spacing: LCSpacing.sm)

            if appState.isOnboardingPresented {
                OnboardingOverlay()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(10)
            }
        }
        .frame(width: appState.preferredPopoverSize.width, height: appState.preferredPopoverSize.height)
        .foregroundStyle(LCPalette.ink)
        .animation(LCAnimation.standard, value: appState.isOnboardingPresented)
    }

    // MARK: - Layout

    private var content: some View {
        VStack(spacing: 0) {
            // Sticky chrome (header + tabs) with its own opaque-ish surface so
            // the scrolling content below cannot bleed through visually.
            VStack(spacing: LCSpacing.xs) {
                header
                    .padding(.horizontal, LCSpacing.lg)
                    .padding(.top, LCSpacing.md)

                tabStrip
                    .padding(.horizontal, LCSpacing.lg)
                    .padding(.bottom, LCSpacing.xs)

                if !appState.message.isEmpty {
                    messageBanner
                        .padding(.horizontal, LCSpacing.lg)
                        .padding(.bottom, LCSpacing.xs)
                        .transition(.opacity)
                }
            }
            .background(.regularMaterial)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(LCPalette.separator)
                    .frame(height: 0.5)
            }

            // Scrollable content area gets all remaining vertical space.
            Group {
                switch appState.selectedTab {
                case .lamps:    LampsView()
                case .settings: SettingsView()
                }
            }
            .padding(.horizontal, LCSpacing.md)
            .padding(.top, LCSpacing.sm)
            .padding(.bottom, LCSpacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .layoutPriority(1)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: LCSpacing.sm) {
            LCIconBadge(systemName: "lightbulb.led",
                        size: 36,
                        tint: LCPalette.accent,
                        fontSize: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text("LampControl")
                    .font(LCTypo.title())
                    .lcTrackedTitle()
                    .foregroundStyle(LCPalette.ink)

                HStack(spacing: LCSpacing.xxs) {
                    LCStatusDot(color: appState.canSync ? Color.blue : LCPalette.muted,
                                animated: appState.isAutoSyncing)
                    Text(headerStatusKey)
                        .font(LCTypo.micro())
                        .foregroundStyle(LCPalette.muted)
                }
            }

            Spacer(minLength: LCSpacing.xs)

            circleIconButton(icon: "gearshape", help: "settings.title") {
                withAnimation(LCAnimation.snap) {
                    appState.selectedTab = .settings
                }
            }

            circleIconButton(icon: "xmark", help: "app.quit", action: appState.quit)
        }
        .frame(height: 56)
    }

    private func circleIconButton(icon: String,
                                  help: LocalizedStringKey,
                                  action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LCPalette.muted)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(LCGlassButtonStyle(prominent: false, radius: 16))
        .help(help)
    }

    // MARK: - Tab strip

    private var tabStrip: some View {
        HStack(spacing: LCSpacing.lg) {
            tabButton(.lamps, title: "tab.lamps", icon: "slider.horizontal.3")
            tabButton(.settings, title: "tab.settings", icon: "gearshape")
            Spacer(minLength: 0)
        }
        .frame(height: 36)
    }

    private func tabButton(_ tab: ControlTab,
                           title: LocalizedStringKey,
                           icon: String) -> some View {
        let isActive = appState.selectedTab == tab

        return Button {
            appState.selectedTab = tab
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                    Text(title)
                        .font(LCTypo.bodySemibold())
                }
                .foregroundStyle(isActive ? LCPalette.ink : LCPalette.muted)

                Group {
                    if isActive {
                        Capsule(style: .continuous)
                            .fill(LCPalette.accent)
                            .matchedGeometryEffect(id: "tab.indicator", in: tabNamespace)
                    } else {
                        Capsule(style: .continuous)
                            .fill(Color.clear)
                    }
                }
                .frame(height: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(LCPressableButtonStyle())
        .animation(LCAnimation.micro, value: isActive)
    }

    // MARK: - Message banner

    private var messageBanner: some View {
        HStack(spacing: LCSpacing.xs) {
            Image(systemName: isErrorMessage ? "exclamationmark.circle.fill" : "info.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isErrorMessage ? LCPalette.danger : LCPalette.accent)
            Text(appState.message)
                .font(LCTypo.caption())
                .foregroundStyle(LCPalette.ink)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, LCSpacing.sm)
        .padding(.vertical, LCSpacing.xs + 2)
        .lcCard(radius: LCRadius.button,
                tint: isErrorMessage
                    ? LCPalette.danger.opacity(0.12)
                    : LCPalette.accent.opacity(0.10))
    }

    // MARK: - Derived

    private var headerStatusKey: LocalizedStringKey {
        appState.canSync ? "cloud.active" : "config.required"
    }

    private var isErrorMessage: Bool {
        let lowered = appState.message.lowercased()
        return lowered.contains("error") || lowered.contains("erreur") ||
               lowered.contains("impossible") || lowered.contains("failed") ||
               lowered.contains("invalide") || lowered.contains("invalid") ||
               lowered.contains("échec")
    }
}

// MARK: - Backwards-compatible LCTheme + liquidGlass helpers
//
// Existing LampsView / SettingsView / OnboardingOverlay still use these
// surfaces extensively. We keep them — they now layer on top of the
// new DesignSystem visuals and continue to work the same way.

extension View {
    /// Apply a Liquid Glass surface.
    /// - On macOS 26+ uses the real `.glassEffect` API.
    /// - On macOS 13–25 falls back to a layered translucent material.
    @ViewBuilder
    func liquidGlassSurface(radius: CGFloat, tint: Color? = nil, interactive: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if #available(macOS 26.0, *) {
            self
                .modifier(NativeGlassEffectModifier(shape: shape, tint: tint, interactive: interactive))
                .contentShape(shape)
        } else {
            self
                .fallbackGlassSurface(radius: radius, tint: tint)
                .contentShape(shape)
        }
    }

    @ViewBuilder
    func liquidGlassCircle(tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            self
                .modifier(NativeGlassEffectModifier(shape: Circle(), tint: tint, interactive: interactive))
                .contentShape(Circle())
        } else {
            self
                .fallbackGlassSurface(radius: 999, tint: tint)
                .contentShape(Circle())
        }
    }

    fileprivate func fallbackGlassSurface(radius: CGFloat, tint: Color?) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return self
            .background(.ultraThinMaterial, in: shape)
            .background(
                LinearGradient(
                    colors: [
                        LCTheme.surfaceTop,
                        (tint ?? LCTheme.surfaceMiddle).opacity(0.22),
                        LCTheme.surfaceBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: shape
            )
            .background(
                Group {
                    if let tint {
                        shape.fill(tint)
                    } else {
                        Color.clear
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                LCTheme.strokeMiddle,
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
    }

    @ViewBuilder
    func liquidGlassButtonStyle(prominent: Bool = false) -> some View {
        self
            .buttonStyle(.plain)
            .liquidGlassSurface(
                radius: prominent ? 18 : 13,
                tint: prominent ? LCTheme.accent.opacity(0.35) : Color.white.opacity(0.08),
                interactive: true
            )
    }
}

@available(macOS 26.0, *)
private struct NativeGlassEffectModifier<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color?
    let interactive: Bool

    func body(content: Content) -> some View {
        if let tint, interactive {
            content.glassEffect(.regular.tint(tint).interactive(), in: shape)
        } else if let tint {
            content.glassEffect(.regular.tint(tint), in: shape)
        } else if interactive {
            content.glassEffect(.regular.interactive(), in: shape)
        } else {
            content.glassEffect(.regular, in: shape)
        }
    }
}

enum LCTheme {
    static let ink = Color.primary
    static let muted = Color.secondary
    static let accent = Color(nsColor: .controlAccentColor)
    static let softAccent = Color(nsColor: .separatorColor)

    static let backgroundTop = Color(nsColor: .windowBackgroundColor).opacity(0.96)
    static let backgroundMiddle = Color(nsColor: .controlBackgroundColor).opacity(0.90)
    static let backgroundBottom = Color(nsColor: .underPageBackgroundColor).opacity(0.92)
    static let glassHighlight = Color(nsColor: .highlightColor).opacity(0.26)
    static let sideHighlight = Color(nsColor: .highlightColor).opacity(0.18)
    static let backgroundShade = Color.black.opacity(0.05)

    static let surfaceTop = Color(nsColor: .controlBackgroundColor).opacity(0.72)
    static let surfaceMiddle = Color(nsColor: .windowBackgroundColor)
    static let surfaceBottom = Color(nsColor: .separatorColor).opacity(0.08)
    static let strokeTop = Color(nsColor: .highlightColor).opacity(0.62)
    static let strokeMiddle = Color(nsColor: .separatorColor).opacity(0.26)
    static let strokeBottom = Color.black.opacity(0.06)
    static let overlayScrim = Color.black.opacity(0.28)

    static let success = Color.green.opacity(0.80)
    static let error = Color.red.opacity(0.80)
    static let errorSurface = Color.red.opacity(0.10)
    static let infoSurface = Color.blue.opacity(0.08)
}
