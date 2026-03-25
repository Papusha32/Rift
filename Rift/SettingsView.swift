import SwiftUI
import ServiceManagement

struct SettingsView: View {
    // 3 Presets
    @AppStorage("preset1") private var preset1 = 10
    @AppStorage("preset2") private var preset2 = 25
    @AppStorage("preset3") private var preset3 = 50

    // Sound
    @AppStorage("selectedSoundPath") private var soundPath = SoundManager.defaultSoundPath
    @AppStorage("alarmVolume") private var alarmVolume = 0.7
    @AppStorage("autoMuteEnabled") private var autoMuteEnabled = true
    @AppStorage("autoMuteSeconds") private var autoMuteSeconds = 5

    // Display
    @AppStorage("floatingDisplayEnabled") private var floatingEnabled = false
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    private let labelColor = Color(white: 0.55)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // --- Timer Presets (3 slots) ---
            VStack(alignment: .leading, spacing: 6) {
                Text("timer presets (min):")
                    .font(.system(size: 12))
                    .foregroundColor(labelColor)

                HStack(spacing: 6) {
                    PresetStepper(value: $preset1)
                    PresetStepper(value: $preset2)
                    PresetStepper(value: $preset3)
                }
            }

            divider

            // --- Alarm Sound ---
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("alarm sound:")
                        .font(.system(size: 12))
                        .foregroundColor(labelColor)

                    Picker("", selection: $soundPath) {
                        ForEach(SoundManager.availableSounds, id: \.url.path) { item in
                            Text(item.name).tag(item.url.path)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)

                    Button {
                        SoundManager.shared.play(
                            soundPath: soundPath,
                            volume: Float(alarmVolume),
                            autoMute: true,
                            muteAfterSeconds: 2
                        )
                    } label: {
                        Image(systemName: "play.circle")
                            .font(.system(size: 13))
                            .foregroundColor(Color(white: 0.5))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("alarm volume:")
                        .font(.system(size: 12))
                        .foregroundColor(labelColor)

                    HStack(spacing: 6) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(white: 0.4))
                        Slider(value: $alarmVolume, in: 0...1)
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(white: 0.4))
                    }
                }

                Toggle(isOn: $autoMuteEnabled) {
                    Text("automatically mute after \(autoMuteSeconds) seconds")
                        .font(.system(size: 12))
                        .foregroundColor(labelColor)
                }
                .toggleStyle(.checkbox)
            }

            divider

            Toggle(isOn: $floatingEnabled) {
                Text("floating timer")
                    .font(.system(size: 12))
                    .foregroundColor(labelColor)
            }
            .toggleStyle(.checkbox)

            Toggle(isOn: $launchAtLogin) {
                Text("launch at login")
                    .font(.system(size: 12))
                    .foregroundColor(labelColor)
            }
            .toggleStyle(.checkbox)
            .onChange(of: launchAtLogin) { newVal in
                try? newVal
                    ? SMAppService.mainApp.register()
                    : SMAppService.mainApp.unregister()
            }

            divider

            HStack {
                Spacer()
                Button("Quit Rift") { NSApp.terminate(nil) }
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.45))
                    .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(14)
        .frame(width: 280)
    }

    private var divider: some View {
        Rectangle().fill(Color(white: 0.22)).frame(height: 1)
    }
}

// MARK: - Preset Stepper

struct PresetStepper: View {
    @Binding var value: Int

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            TextField("1", text: $text)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(width: 34)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onChange(of: text) { newVal in
                    let digits = String(newVal.filter(\.isNumber).prefix(3))
                    if digits != newVal { text = digits }
                    if let n = Int(digits), n >= 1, n <= 240, n != value {
                        value = n
                    }
                }
                .onChange(of: value) { newVal in
                    guard !isFocused else { return }
                    let s = "\(newVal)"
                    if text != s { text = s }
                }
                .onChange(of: isFocused) { focused in
                    if !focused {
                        if text.isEmpty || (Int(text) ?? 0) < 1 { value = 1 }
                        else if let n = Int(text), n > 240 { value = 240 }
                        text = "\(value)"
                    }
                }
                .onAppear { text = "\(value)" }
                .onSubmit { isFocused = false }

            VStack(spacing: 0) {
                Button { if value < 240 { value += 1; text = "\(value)" } } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Color(white: 0.5))
                        .frame(width: 16, height: 12)
                }
                .buttonStyle(.plain)

                Button { if value > 1 { value -= 1; text = "\(value)" } } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Color(white: 0.5))
                        .frame(width: 16, height: 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color(white: 0.2))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}
