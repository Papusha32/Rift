import AVFoundation
import AppKit

struct SoundItem: Hashable {
    let name: String
    let url: URL

    static func == (lhs: SoundItem, rhs: SoundItem) -> Bool { lhs.url == rhs.url }
    func hash(into hasher: inout Hasher) { hasher.combine(url) }
}

class SoundManager {
    static let shared = SoundManager()

    private var audioPlayer: AVAudioPlayer?
    private var muteWorkItem: DispatchWorkItem?

    /// Scans macOS system sounds + iOS-style alert/ringtones from ToneLibrary
    static let availableSounds: [SoundItem] = {
        var items: [SoundItem] = []
        let exts: Set<String> = ["aiff", "aif", "wav", "caf", "m4r", "mp3"]

        let dirs = [
            "/System/Library/Sounds",
            "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones",
            "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones",
        ]

        for dir in dirs {
            let base = URL(fileURLWithPath: dir)
            guard let enumerator = FileManager.default.enumerator(
                at: base, includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }

            while let fileURL = enumerator.nextObject() as? URL {
                guard exts.contains(fileURL.pathExtension.lowercased()) else { continue }
                let name = fileURL.deletingPathExtension().lastPathComponent
                items.append(SoundItem(name: name, url: fileURL))
            }
        }

        // Deduplicate by name (prefer first found), sort
        var seen = Set<String>()
        var unique: [SoundItem] = []
        for item in items {
            if seen.insert(item.name).inserted {
                unique.append(item)
            }
        }
        return unique.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }()

    /// Default sound path for first launch
    static let defaultSoundPath: String = {
        availableSounds.first(where: { $0.name == "Glass" })?.url.path
            ?? availableSounds.first?.url.path
            ?? "/System/Library/Sounds/Glass.aiff"
    }()

    func play(
        soundPath: String,
        volume: Float = 0.8,
        autoMute: Bool = false,
        muteAfterSeconds: Int = 5
    ) {
        stop()

        let url = URL(fileURLWithPath: soundPath)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = max(0, min(1, volume))
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
        } catch {
            NSSound.beep()
            return
        }

        if autoMute && muteAfterSeconds > 0 {
            let work = DispatchWorkItem { [weak self] in self?.stop() }
            muteWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(muteAfterSeconds), execute: work)
        }
    }

    func stop() {
        muteWorkItem?.cancel()
        muteWorkItem = nil
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
