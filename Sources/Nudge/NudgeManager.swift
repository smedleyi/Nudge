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
        if saved > 0 {
            interval = saved
        } else {
            interval = 20
            // didSet doesn't fire for this assignment (Swift skips observers
            // during init), so persist the default explicitly.
            UserDefaults.standard.set(interval, forKey: "nudgeInterval")
        }
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
        let newTimer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.nudge()
        }
        // .common (not just .default) so the timer keeps firing while the
        // status-bar menu is open, since AppKit runs the run loop in
        // .eventTracking mode during menu tracking.
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func nudge() {
        guard let location = CGEvent(source: nil)?.location else { return }
        let delta: CGFloat = moveRight ? 1 : -1
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
        moveRight.toggle()
    }
}
