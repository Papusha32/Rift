import AppKit
import SwiftUI
import Combine

final class UpdateWindowController: NSWindowController {
    private let updateStore: UpdateStore
    private var cancellable: AnyCancellable?

    init(updateStore: UpdateStore) {
        self.updateStore = updateStore

        let view = UpdateView()
            .environmentObject(updateStore)

        let vc = NSHostingController(rootView: view)
        vc.view.appearance = NSAppearance(named: .darkAqua)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.contentViewController = vc
        panel.center()

        super.init(window: panel)

        // Show/hide based on update state
        cancellable = updateStore.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                switch newState {
                case .available, .downloading, .downloaded, .installing, .error:
                    self?.showWindow(nil)
                    NSApp.activate(ignoringOtherApps: true)
                case .idle:
                    self?.window?.orderOut(nil)
                }
            }
    }

    required init?(coder: NSCoder) { fatalError() }
}
