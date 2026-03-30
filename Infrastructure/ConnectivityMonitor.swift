import Foundation
import Network

@MainActor
protocol ConnectivityMonitoring: AnyObject {
    var currentStatus: ConnectivityStatus { get }
    func updates() -> AsyncStream<ConnectivityStatus>
}

enum ConnectivityStatus: Equatable {
    case online
    case offline

    var isOnline: Bool {
        self == .online
    }
}

@MainActor
final class NetworkConnectivityMonitor: ConnectivityMonitoring {
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "SwipeMail.NetworkConnectivityMonitor")
    private var currentValue: ConnectivityStatus
    private var continuations: [UUID: AsyncStream<ConnectivityStatus>.Continuation] = [:]

    init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
        self.currentValue = Self.status(for: monitor.currentPath)

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else {
                return
            }

            let status = Self.status(for: path)
            Task { @MainActor in
                self.publish(status)
            }
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    var currentStatus: ConnectivityStatus {
        currentValue
    }

    func updates() -> AsyncStream<ConnectivityStatus> {
        AsyncStream { continuation in
            let id = UUID()
            continuations[id] = continuation
            continuation.yield(currentValue)

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    private func publish(_ status: ConnectivityStatus) {
        guard status != currentValue else {
            return
        }

        currentValue = status
        continuations.values.forEach { $0.yield(status) }
    }

    nonisolated private static func status(for path: NWPath) -> ConnectivityStatus {
        path.status == .satisfied ? .online : .offline
    }
}
