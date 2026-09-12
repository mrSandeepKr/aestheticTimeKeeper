import Foundation

/// Runs async operations strictly one at a time, in the order they were enqueued:
/// each waits for the previous to finish before it starts.
///
/// ActivityKit applies updates as they arrive, so two overlapping calls can land
/// out of order. Funnelling every ActivityKit call through one of these keeps the
/// last state pushed as the last state applied.
@MainActor
final class SerialTaskQueue {
    private var tail: Task<Void, Never>?

    func enqueue(_ operation: @escaping @MainActor () async -> Void) {
        let previous = tail
        tail = Task { @MainActor in
            await previous?.value
            await operation()
        }
    }
}
