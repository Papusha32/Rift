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

    /// Curated gentle sounds suitable for timer alerts
    private static let allowedSounds: Set<String> = [
        "Glass", "Breeze", "Crystal", "Heroine", "Ping",
        "Pop", "Purr", "Sosumi", "Tink", "Blow",
        "Bottle", "Frog", "Morse", "Submarine"
    ]

    static let availableSounds: [SoundItem] = {
        var items: [SoundItem] = []
        let exts: Set<String> = ["aiff", "aif", "wav", "caf"]

        let base = URL(fileURLWithPath: "/System/Library/Sounds")
        guard let enumerator = FileManager.default.enumerator(
            at: base, includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        while let fileURL = enumerator.nextObject() as? URL {
            guard exts.contains(fileURL.pathExtension.lowercased()) else { continue }
            let name = fileURL.deletingPathExtension().lastPathComponent
            guard allowedSounds.contains(name) else { continue }
            items.append(SoundItem(name: name, url: fileURL))
        }

        return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
