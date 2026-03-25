import AppKit
import SwiftUI
import UserNotifications

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var timerManager: TimerManager
    private var floatingWindowController: FloatingWindowController?
    private var cancellables: [Any] = []
    private var globalClickMonitor: Any?

    /// Fixed pill width so the menu bar icon never jumps
    private var fixedPillWidth: CGFloat = 0

    override init() {
        timerManager = TimerManager()
        super.init()

        computeFixedPillWidth()
        setupStatusItem()
        setupPopover()
        setupFloatingWindow()
        setupTimerCallbacks()
        requestNotificationPermission()
        observeFloatingWindowClick()
    }

    func cleanup() { floatingWindowController?.cleanup() }

    // MARK: - Fixed Pill Width

    private func computeFixedPillWidth() {
        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        // Widest possible text: "0:00:00" (hour format)
        let maxText = NSAttributedString(string: "0:00:00", attributes: attrs)
        fixedPillWidth = maxText.size().width + 18 // +hPad*2 + border
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: fixedPillWidth + 4)
        guard let button = statusItem?.button else { return }
        button.imagePosition = .imageOnly
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.action = #selector(handleButtonClick)
        button.target = self
        updateMenuBarPill()
    }

    @objc private func handleButtonClick() {
        guard let event = NSApp.currentEvent else { return }
        event.type == .rightMouseUp ? handleRightClick() : togglePopover()
    }

    private func handleRightClick() {
        switch timerManager.state {
        case .idle, .completed:
            timerManager.start(minutes: timerManager.selectedMinutes)
        case .running, .paused:
            timerManager.stop()
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 120)
        popover.behavior = .transient
        popover.animates = true
        let vc = NSHostingController(rootView: TimerPopoverView(timerManager: timerManager))
        vc.view.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = vc
        self.popover = popover
    }

    func showPopover() {
        guard let button = statusItem?.button else { return }
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover?.contentViewController?.view.window?.makeKey()
        startGlobalClickMonitor()
    }

    private func closePopover() {
        popover?.performClose(nil)
        stopGlobalClickMonitor()
    }

    private func startGlobalClickMonitor() {
        stopGlobalClickMonitor()
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard self?.popover?.isShown == true else { return }
            self?.closePopover()
        }
    }

    private func stopGlobalClickMonitor() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
    }

    @objc private func togglePopover() {
        popover?.isShown == true ? closePopover() : showPopover()
    }

    // MARK: - Floating Window

    private func setupFloatingWindow() {
        floatingWindowController = FloatingWindowController(timerManager: timerManager)
    }

    private func handleFloatingWindowVisibility(state: TimerState) {
        guard UserDefaults.standard.bool(forKey: "floatingDisplayEnabled") else { return }
        switch state {
        case .running, .paused: floatingWindowController?.show()
        case .idle, .completed: floatingWindowController?.hide()
        }
    }

    // MARK: - Timer Callbacks

    private func setupTimerCallbacks() {
        timerManager.onCompletion = { [weak self] in self?.handleTimerCompleted() }

        let stateObs = timerManager.$state.sink { [weak self] state in
            DispatchQueue.main.async {
                self?.updateMenuBarPill()
                self?.handleFloatingWindowVisibility(state: state)
            }
        }
        cancellables.append(stateObs)

        let tickObs = timerManager.$remainingSeconds.sink { [weak self] _ in
            DispatchQueue.main.async { self?.updateMenuBarPill() }
        }
        cancellables.append(tickObs)

        let selObs = timerManager.$selectedMinutes.sink { [weak self] _ in
            DispatchQueue.main.async { self?.updateMenuBarPill() }
        }
        cancellables.append(selObs)
    }

    private func handleTimerCompleted() {
        let defs = UserDefaults.standard
        let soundPath = defs.string(forKey: "selectedSoundPath") ?? SoundManager.defaultSoundPath
        let vol = defs.double(forKey: "alarmVolume")
        let mute = defs.bool(forKey: "autoMuteEnabled")
        let muteSec = defs.integer(forKey: "autoMuteSeconds")

        SoundManager.shared.play(
            soundPath: soundPath,
            volume: Float(vol > 0 ? vol : 0.7),
            autoMute: mute,
            muteAfterSeconds: muteSec > 0 ? muteSec : 5
        )

        sendCompletionNotification()

    }

    // MARK: - Menu Bar Pill (fixed width)

    private func updateMenuBarPill() {
        guard let button = statusItem?.button else { return }

        let isActive = timerManager.state == .running || timerManager.state == .paused
        let isPaused = timerManager.state == .paused
        let text: String

        switch timerManager.state {
        case .idle:
            let h = timerManager.selectedMinutes / 60
            let m = timerManager.selectedMinutes % 60
            text = h > 0 ? String(format: "%d:%02d:00", h, m) : String(format: "%02d:00", m)
        case .running, .paused:
            text = timerManager.timeString
        case .completed:
            text = "00:00"
        }

        button.image = drawPill(text: text, isActive: isActive, isPaused: isPaused)
        button.title = ""
    }

    private func drawPill(text: String, isActive: Bool, isPaused: Bool) -> NSImage {
        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)

        let textColor: NSColor = isActive
            ? NSColor(name: nil, dynamicProvider: { app in
                app.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .black : .white
              })
            : NSColor.labelColor

        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let str = NSAttributedString(string: text, attributes: attrs)
        let textSize = str.size()

        let hPad: CGFloat = 8
        let vPad: CGFloat = 2
        // Use fixed minimum width so pill never changes size
        let pillContentWidth = max(textSize.width, fixedPillWidth - hPad * 2)
        let w = pillContentWidth + hPad * 2
        let h = textSize.height + vPad * 2

        let image = NSImage(size: NSSize(width: w, height: h), flipped: false) { rect in
            let inset = rect.insetBy(dx: 0.5, dy: 0.5)
            let radius = inset.height / 2
            let path = NSBezierPath(roundedRect: inset, xRadius: radius, yRadius: radius)

            if isActive {
                NSColor.labelColor.withAlphaComponent(isPaused ? 0.5 : 1.0).setFill()
                path.fill()
            } else {
                NSColor.labelColor.withAlphaComponent(0.1).setFill()
                path.fill()
                NSColor.labelColor.withAlphaComponent(0.45).setStroke()
                path.lineWidth = 0.75
                path.stroke()
            }

            let tx = (rect.width - textSize.width) / 2
            let ty = (rect.height - textSize.height) / 2
            str.draw(at: NSPoint(x: tx, y: ty))
            return true
        }
        image.isTemplate = false
        return image
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Rift"
        content.body = "Time's up! Take a break."
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "rift.completion", content: content, trigger: nil)
        ) { _ in }
    }

    @objc private func openPopoverFromFloat() { showPopover() }

    private func observeFloatingWindowClick() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(openPopoverFromFloat),
            name: .floatingWindowClicked, object: nil
        )
    }
}
