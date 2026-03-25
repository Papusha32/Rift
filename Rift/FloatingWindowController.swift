import AppKit
import SwiftUI

class FloatingWindowController: NSObject {
    private var panel: NSPanel?
    private var timerManager: TimerManager

    private let positionKey = "floatingWindowPosition"

    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        super.init()
    }

    func show() {
        if panel == nil {
            createPanel()
        }
        panel?.orderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func cleanup() {
        panel?.close()
        panel = nil
    }

    private func createPanel() {
        let contentView = FloatingDisplayView(timerManager: timerManager)
        let hosting = NSHostingView(rootView: contentView)

        let panelSize = NSSize(width: 140, height: 44)
        let savedPosition = loadPosition()

        let newPanel = DraggablePanel(
            contentRect: NSRect(origin: savedPosition, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.level = .floating
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = true
        newPanel.isMovableByWindowBackground = false
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Visual effect background
        let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: panelSize))
        effectView.blendingMode = .behindWindow
        effectView.material = .hudWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 12

        hosting.frame = effectView.bounds
        hosting.autoresizingMask = [.width, .height]
        effectView.addSubview(hosting)

        newPanel.contentView = effectView

        // Click to open popover
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(panelClicked))
        effectView.addGestureRecognizer(clickGesture)

        // Handle drag — save position
        (newPanel as? DraggablePanel)?.onDragEnded = { [weak self] origin in
            self?.savePosition(origin)
        }

        self.panel = newPanel
    }

    @objc private func panelClicked() {
        // Notify to open popover — post notification
        NotificationCenter.default.post(name: .floatingWindowClicked, object: nil)
    }

    private func savePosition(_ origin: NSPoint) {
        UserDefaults.standard.set(NSStringFromPoint(origin), forKey: positionKey)
    }

    private func loadPosition() -> NSPoint {
        if let str = UserDefaults.standard.string(forKey: positionKey) {
            return NSPointFromString(str)
        }
        // Default: bottom-right area
        if let screen = NSScreen.main {
            return NSPoint(
                x: screen.visibleFrame.maxX - 160,
                y: screen.visibleFrame.minY + 60
            )
        }
        return NSPoint(x: 100, y: 100)
    }
}

// MARK: - Draggable NSPanel

class DraggablePanel: NSPanel {
    var onDragEnded: ((NSPoint) -> Void)?
    private var dragStart: NSPoint = .zero

    override func mouseDown(with event: NSEvent) {
        dragStart = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        let current = event.locationInWindow
        let dx = current.x - dragStart.x
        let dy = current.y - dragStart.y
        let newOrigin = NSPoint(x: frame.origin.x + dx, y: frame.origin.y + dy)
        setFrameOrigin(newOrigin)
    }

    override func mouseUp(with event: NSEvent) {
        onDragEnded?(frame.origin)
    }
}

extension Notification.Name {
    static let floatingWindowClicked = Notification.Name("floatingWindowClicked")
}
