import Foundation
import AppKit

@MainActor
final class UpdateStore: ObservableObject {
    @Published var state: UpdateState = .idle

    private let service = UpdateService()

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    // MARK: - Check for updates (silent on failure)

    func checkForUpdates() {
        Task {
            do {
                if let update = try await service.checkForUpdate() {
                    state = .available(version: update.version, downloadURL: update.url)
                }
            } catch {
                // Not critical — user just won't see update notification
            }
        }
    }

    // MARK: - Download

    func downloadUpdate() {
        guard case .available(_, let url) = state else { return }
        state = .downloading(progress: 0)
        Task {
            do {
                let fileURL = try await service.downloadUpdate(from: url) { [weak self] progress in
                    Task { @MainActor in
                        self?.state = .downloading(progress: progress)
                    }
                }
                state = .downloaded(fileURL: fileURL)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Install

    func installUpdate() {
        guard case .downloaded(let dmgURL) = state else { return }
        state = .installing

        let scriptPath = NSTemporaryDirectory() + "rift-update.sh"
        let dmgPath = dmgURL.path

        // Shell script that:
        // 1. Waits for this app to quit
        // 2. Mounts the DMG
        // 3. Copies Rift.app to /Applications
        // 4. Removes quarantine
        // 5. Launches the new version
        let script = """
        #!/bin/bash
        # Wait for Rift to quit
        while pgrep -x "Rift" > /dev/null 2>&1; do sleep 0.3; done
        sleep 0.5

        # Mount DMG
        MOUNT=$(hdiutil attach '\(dmgPath)' -nobrowse 2>/dev/null | grep '/Volumes/' | head -1 | awk -F'\\t' '{print $NF}')
        [ -z "$MOUNT" ] && exit 1

        # Install
        rm -rf /Applications/Rift.app
        cp -R "$MOUNT/Rift.app" /Applications/
        xattr -cr /Applications/Rift.app

        # Cleanup
        hdiutil detach "$MOUNT" -quiet 2>/dev/null
        rm -f '\(dmgPath)' '\(scriptPath)'

        # Launch new version
        open /Applications/Rift.app
        """

        do {
            try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755], ofItemAtPath: scriptPath
            )
        } catch {
            state = .error("Could not write install script: \(error.localizedDescription)")
            return
        }

        // Launch script as detached process so it survives after this app quits
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptPath]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            state = .error("Could not launch installer: \(error.localizedDescription)")
            return
        }

        // Quit after 1 second — the script waits for us to quit, then installs
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NSApp.terminate(nil)
        }
    }

    // MARK: - Dismiss

    func dismiss() {
        state = .idle
    }
}
