import Foundation
import Sparkle

@MainActor
final class UpdateService: NSObject, ObservableObject {
    @Published private(set) var lastCheckedAt: Date?
    @Published var automaticChecksEnabled = false
    @Published var automaticDownloadsEnabled = false

    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    var currentBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    var feedURL: String {
        updaterController.updater.feedURL?.absoluteString ?? ""
    }

    override init() {
        super.init()
    }

    func start() {
        // Updater is already started in init via startingUpdater: true
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
        lastCheckedAt = Date()
    }

    var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
    }
}
