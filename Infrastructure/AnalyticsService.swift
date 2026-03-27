import Foundation

protocol AnalyticsService {
    func track(_ event: AnalyticsEvent)
}

struct AnalyticsEvent: Sendable {
    let name: String
    let properties: [String: String]

    init(name: String, properties: [String: String] = [:]) {
        self.name = name
        self.properties = properties
    }
}

struct NoOpAnalyticsService: AnalyticsService {
    func track(_ event: AnalyticsEvent) {}
}
