import Foundation

@@/// Represents an available macOS Focus mode
@@struct FocusMode: Identifiable, Hashable {
@@    var identifier: String      // e.g., "do-not-disturb", "focus", "sleep"
@@    var displayName: String     // e.g., "Ne pas déranger", "Focus", "Repos"
@@    var id: String { identifier }
@@}
@@
/// Maps a macOS Focus mode to a lamp scene
struct FocusMapping: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var focusIdentifier: String  // e.g., "work", "sleep", "custom-name"
    var focusDisplayName: String // e.g., "Travail", "Sommeil"
    var sceneId: UUID?           // UserLightScene ID or preset scene ID
    var isEnabled: Bool = true

    init(id: String = UUID().uuidString, focusIdentifier: String, focusDisplayName: String, sceneId: UUID? = nil, isEnabled: Bool = true) {
        self.id = id
        self.focusIdentifier = focusIdentifier
        self.focusDisplayName = focusDisplayName
        self.sceneId = sceneId
        self.isEnabled = isEnabled
    }
}
