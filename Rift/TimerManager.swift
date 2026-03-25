import Foundation
import Combine

enum TimerState {
    case idle
    case running
    case paused
    case completed
}

class TimerManager: ObservableObject {
    @Published var totalSeconds: Int = 25 * 60
    @Published var remainingSeconds: Int = 25 * 60
    @Published var state: TimerState = .idle
    @Published var selectedMinutes: Int = 25

    var isRunning: Bool { state == .running }
    var isPaused: Bool { state == .paused }
    var isCompleted: Bool { state == .completed }
    var isIdle: Bool { state == .idle }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - Double(remainingSeconds) / Double(totalSeconds)
    }

    /// Formatted remaining time — shows H:MM:SS when >= 1h, MM:SS otherwise
    var timeString: String {
        let h = remainingSeconds / 3600
        let m = (remainingSeconds % 3600) / 60
        let s = remainingSeconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private var dispatchTimer: DispatchSourceTimer?
    var onCompletion: (() -> Void)?

    func start(minutes: Int) {
        selectedMinutes = minutes
        let seconds = minutes * 60
        totalSeconds = seconds
        remainingSeconds = seconds
        state = .running
        startDispatchTimer()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        dispatchTimer?.suspend()
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        dispatchTimer?.resume()
    }

    func stop() {
        cancelTimer()
        state = .idle
    }

    func reset() {
        cancelTimer()
        remainingSeconds = totalSeconds
        state = .idle
    }

    func dismissCompleted() {
        SoundManager.shared.stop()
        cancelTimer()
        state = .idle
    }

    // MARK: - Private

    private func startDispatchTimer() {
        cancelTimer()
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInteractive))
        timer.schedule(deadline: .now() + 1, repeating: 1.0)
        timer.setEventHandler { [weak self] in self?.tick() }
        dispatchTimer = timer
        timer.resume()
    }

    private func tick() {
        guard state == .running else { return }
        DispatchQueue.main.async {
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            }
            if self.remainingSeconds == 0 {
                self.state = .completed
                self.cancelTimer()
                self.onCompletion?()
            }
        }
    }

    private func cancelTimer() {
        if let timer = dispatchTimer {
            if state == .paused { timer.resume() }
            timer.cancel()
            dispatchTimer = nil
        }
    }

    deinit { cancelTimer() }
}
