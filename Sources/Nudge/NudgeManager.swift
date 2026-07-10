import CoreGraphics
import Foundation

/// Posts a synthetic 1px mouse-moved event on a timer, alternating direction each
/// tick so the cursor drifts back and forth rather than walking off screen. This
/// resets the system idle timer the same way real hardware input does, which is
/// enough to keep status-tracking apps (Slack, Teams, etc.) from marking you away.
final class NudgeManager {
    static let shared = NudgeManager()

    private(set) var isRunning = false

    private(set) var interval: TimeInterval {
        didSet { UserDefaults.standard.set(interval, forKey: "nudgeInterval") }
    }

    private var timer: Timer?
    private var moveRight = true

    private init() {
        let saved = UserDefaults.standard.double(forKey: "nudgeInterval")
        interval = saved > 0 ? saved : 20
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        scheduleTimer()
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func setInterval(_ newInterval: TimeInterval) {
        interval = newInterval
        if isRunning {
            timer?.invalidate()
            scheduleTimer()
        }
    }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.nudge()
        }
    }

    private func nudge() {
        guard let location = CGEvent(source: nil)?.location else { return }
        let delta: CGFloat = moveRight ? 1 : -1
        moveRight.toggle()
        let newLocation = CGPoint(x: location.x + delta, y: location.y)
        guard
            let event = CGEvent(
                mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: newLocation,
                mouseButton: .left
            )
        else { return }
        event.post(tap: .cghidEventTap)
    }
}
