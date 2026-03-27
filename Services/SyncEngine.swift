import Foundation

protocol SyncEngine {
    func syncPendingWork() async
}

struct PlaceholderSyncEngine: SyncEngine {
    func syncPendingWork() async {}
}
