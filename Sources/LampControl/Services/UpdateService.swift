import Combine
import Foundation
import Sparkle

/// Wraps Sparkle's `SPUStandardUpdaterController` and exposes its preferences
/// as `@Published` bindings so SwiftUI toggles can read AND persist them.
///
/// The previous version held the toggles in plain @Published properties with
/// no link back to Sparkle: the UI changed, nothing happened, and the values
/// reset to `false` on every launch. We now read the current Sparkle state on
/// init and forward every change back to `SPUUpdater`, which persists the
/// settings in `UserDefaults` automatically (under the SUEnableAutomaticChecks
/// / SUAutomaticallyUpdate keys).
@MainActor
final class UpdateService: NSObject, ObservableObject {
    @Published private(set) var lastCheckedAt: Date?

    @Published var automaticChecksEnabled: Bool {
        didSet {
            guard !syncingFromSparkle else { return }
            updaterController.updater.automaticallyChecksForUpdates = automaticChecksEnabled
        }
    }

    @Published var automaticDownloadsEnabled: Bool {
        didSet {
            guard !syncingFromSparkle else { return }
            updaterController.updater.automaticallyDownloadsUpdates = automaticDownloadsEnabled
        }
    }

    private let updaterController: SPUStandardUpdaterController
    private var syncingFromSparkle = false
    private var cancellables = Set<AnyCancellable>()

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    var currentBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    var feedURL: String {
        updaterController.updater.feedURL?.absoluteString ?? ""
    }

    var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
    }

    override init() {
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        self.updaterController = controller
        // Seed the published properties from Sparkle's persisted state so the
        // toggles reflect reality immediately after launch.
        self.automaticChecksEnabled    = controller.updater.automaticallyChecksForUpdates
        self.automaticDownloadsEnabled = controller.updater.automaticallyDownloadsUpdates
        super.init()

        // Reflect Sparkle's last update check date back into the UI.
        controller.updater.publisher(for: \.lastUpdateCheckDate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] date in self?.lastCheckedAt = date }
            .store(in: &cancellables)
    }

    func start() {
        // The updater is already running (started in init via `startingUpdater: true`).
        // If automatic checks are enabled, kick off one check now so the user gets
        // an answer when they open the popover after launch — the daily Sparkle
        // schedule alone can leave them waiting hours.
        if updaterController.updater.automaticallyChecksForUpdates,
           updaterController.updater.canCheckForUpdates {
            updaterController.updater.checkForUpdatesInBackground()
        }
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
        lastCheckedAt = Date()
    }
}
