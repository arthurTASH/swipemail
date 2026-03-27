import Foundation
import OSLog

protocol AppLogger {
    func debug(_ message: String, metadata: [String: String])
    func info(_ message: String, metadata: [String: String])
    func error(_ message: String, metadata: [String: String])
}

struct OSAppLogger: AppLogger {
    private let logger = Logger(subsystem: "com.swipemail.app", category: "application")

    func debug(_ message: String, metadata: [String: String] = [:]) {
        logger.debug("\(format(message: message, metadata: metadata), privacy: .public)")
    }

    func info(_ message: String, metadata: [String: String] = [:]) {
        logger.info("\(format(message: message, metadata: metadata), privacy: .public)")
    }

    func error(_ message: String, metadata: [String: String] = [:]) {
        logger.error("\(format(message: message, metadata: metadata), privacy: .public)")
    }

    private func format(message: String, metadata: [String: String]) -> String {
        guard !metadata.isEmpty else {
            return message
        }

        let renderedMetadata = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")

        return "\(message) \(renderedMetadata)"
    }
}

enum SensitiveValueRedactor {
    static func redact(_ value: String) -> String {
        guard !value.isEmpty else {
            return "<empty>"
        }

        return "<redacted:\(value.count)>"
    }
}
