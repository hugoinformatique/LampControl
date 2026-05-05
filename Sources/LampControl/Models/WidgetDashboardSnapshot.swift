import Foundation

struct WidgetDashboardSnapshot: Codable, Equatable {
    var generatedAt: Date = Date()
    var totalLampCount: Int
    var onlineLampCount: Int
    var poweredOnLampCount: Int
    var sceneCount: Int
    var sceneTitles: [String]
    var activeRoomCount: Int
    var roomTitles: [String]
}