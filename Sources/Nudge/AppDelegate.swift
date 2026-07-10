import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let intervals: [TimeInterval] = [10, 20, 30, 60, 120, 300]

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        buildMenu()
        NudgeManager.shared.start()
        refresh()
    }

    private func buildMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: "", action: #selector(toggleNudging), keyEquivalent: "")
        toggleItem.target = self
        toggleItem.tag = 100
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let intervalMenu = NSMenu()
        for seconds in intervals {
            let item = NSMenuItem(
                title: label(for: seconds), action: #selector(selectInterval(_:)),
                keyEquivalent: "")
            item.target = self
            item.representedObject = seconds
            intervalMenu.addItem(item)
        }
        let intervalItem = NSMenuItem(title: "Interval", action: nil, keyEquivalent: "")
        intervalItem.submenu = intervalMenu
        menu.addItem(intervalItem)

        menu.addItem(NSMenuItem.separator())

        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.target = self
        launchAtLoginItem.tag = 200
        menu.addItem(launchAtLoginItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quit Nudge", action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"))

        statusItem.menu = menu
    }

    private func label(for seconds: TimeInterval) -> String {
        seconds < 60 ? "\(Int(seconds))s" : "\(Int(seconds / 60))m"
    }

    @objc private func toggleNudging() {
        if NudgeManager.shared.isRunning {
            NudgeManager.shared.stop()
        } else {
            NudgeManager.shared.start()
        }
        refresh()
    }

    @objc private func selectInterval(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? TimeInterval else { return }
        NudgeManager.shared.setInterval(seconds)
        refresh()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Nudge: failed to toggle launch at login: \(error)")
        }
        refresh()
    }

    private func refresh() {
        guard let menu = statusItem.menu else { return }

        if let toggleItem = menu.item(withTag: 100) {
            toggleItem.title = NudgeManager.shared.isRunning ? "Stop Nudging" : "Start Nudging"
        }

        if let intervalItem = menu.items.first(where: { $0.submenu != nil }),
            let submenu = intervalItem.submenu
        {
            for item in submenu.items {
                guard let seconds = item.representedObject as? TimeInterval else { continue }
                item.state = seconds == NudgeManager.shared.interval ? .on : .off
            }
        }

        if let launchAtLoginItem = menu.item(withTag: 200) {
            launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }

        let symbolName = NudgeManager.shared.isRunning ? "cursorarrow.motionlines" : "cursorarrow"
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Nudge") {
            image.isTemplate = true
            statusItem.button?.image = image
        } else {
            statusItem.button?.title = NudgeManager.shared.isRunning ? "on" : "off"
        }
    }
}
