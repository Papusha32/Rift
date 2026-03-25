import SwiftUI

// MARK: - Main Popover

struct TimerPopoverView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var showSettings = false
    @State private var dismissDigitEditing = false

    @AppStorage("preset1") private var p1 = 10
    @AppStorage("preset2") private var p2 = 25
    @AppStorage("preset3") private var p3 = 50

    private var presets: [Int] { [p1, p2, p3] }
    private let bg = Color(red: 0.13, green: 0.13, blue: 0.13)

    var body: some View {
        ZStack {
            // Background tap to dismiss digit editing
            bg.ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissDigitEditing.toggle()
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }
            VStack(spacing: 0) {
                switch timerManager.state {
                case .idle:                idleView
                case .running, .paused:    runningView
                case .completed:           completedView
                }
            }
        }
        .frame(width: 340, height: 120)
        .onKeyPress(.space) { handleSpaceKey(); return .handled }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 0) {
            HorizontalTickSlider(minutes: $timerManager.selectedMinutes)
                .frame(height: 30)
                .padding(.horizontal, 14)
                .padding(.top, 10)

            // 3 Presets + "..."
            HStack(spacing: 4) {
                ForEach(Array(presets.enumerated()), id: \.offset) { _, p in
                    Button { timerManager.selectedMinutes = p } label: {
                        Text("\(p)m")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(timerManager.selectedMinutes == p ? .white : Color(white: 0.5))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(timerManager.selectedMinutes == p ? Color(white: 0.32) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button { showSettings.toggle() } label: {
                    Text("···")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(white: 0.4))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showSettings) {
                    SettingsView().preferredColorScheme(.dark)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)

            Spacer(minLength: 4)

            HStack(alignment: .lastTextBaseline) {
                Button { timerManager.start(minutes: timerManager.selectedMinutes) } label: {
                    Text("start")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.7))
                }
                .buttonStyle(.plain)

                Spacer()

                TimeInputView(selectedMinutes: $timerManager.selectedMinutes, dismissTrigger: dismissDigitEditing)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Running / Paused — tick slider as progress

    private var runningView: some View {
        VStack(spacing: 0) {
            ProgressTickView(progress: timerManager.progress)
                .frame(height: 30)
                .padding(.horizontal, 14)
                .padding(.top, 10)

            Spacer()

            HStack(alignment: .lastTextBaseline) {
                HStack(spacing: 0) {
                    Button {
                        timerManager.isRunning ? timerManager.pause() : timerManager.resume()
                    } label: {
                        Text(timerManager.isRunning ? "pause" : "resume")
                            .font(.system(size: 13))
                            .foregroundColor(Color(white: 0.7))
                    }
                    .buttonStyle(.plain)

                    Text("  ·  ")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.28))

                    Button { timerManager.stop() } label: {
                        Text("stop")
                            .font(.system(size: 13))
                            .foregroundColor(Color(white: 0.42))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Text(timerManager.timeString)
                    .font(.system(size: 28, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.linear(duration: 0.4), value: timerManager.remainingSeconds)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Completed

    private var completedView: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(alignment: .lastTextBaseline) {
                Button { timerManager.dismissCompleted() } label: {
                    Text("dismiss")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.7))
                }
                .buttonStyle(.plain)
                Spacer()
                Text("00:00")
                    .font(.system(size: 28, weight: .thin, design: .monospaced))
                    .foregroundColor(Color(white: 0.45))
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
    }

    private func handleSpaceKey() {
        switch timerManager.state {
        case .running: timerManager.pause()
        case .paused:  timerManager.resume()
        default: break
        }
    }
}

// MARK: - Progress Tick View (read-only slider showing remaining time)

struct ProgressTickView: View {
    let progress: Double   // 0 = just started, 1 = complete

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cursorX = (1.0 - progress) * Double(w)

            ZStack(alignment: .leading) {
                // Tick marks (decorative)
                Canvas { ctx, size in
                    for i in 0...90 {
                        let x = CGFloat(i) / 90.0 * size.width
                        let isMajor  = i % 15 == 0
                        let isMedium = i % 5 == 0
                        let tickH: CGFloat = isMajor  ? size.height * 0.65
                                           : isMedium ? size.height * 0.4
                                           : size.height * 0.22
                        let y = (size.height - tickH) / 2
                        // Ticks to the right of cursor are dimmed (elapsed)
                        let dimmed = Double(x) > cursorX
                        let base: CGFloat = isMajor ? 0.5 : isMedium ? 0.3 : 0.15
                        let alpha = dimmed ? base * 0.3 : base

                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x, y: y + tickH))
                        ctx.stroke(path,
                                   with: .color(.white.opacity(Double(alpha))),
                                   lineWidth: 0.6)
                    }
                }
                .frame(width: w, height: h)

                // White cursor — remaining time position
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white)
                    .frame(width: 2, height: h * 0.85)
                    .offset(x: CGFloat(cursorX) - 1)
                    .animation(.linear(duration: 1), value: progress)
            }
        }
    }
}

// MARK: - Time Input (00H 00M)

struct TimeInputView: View {
    @Binding var selectedMinutes: Int
    var dismissTrigger: Bool = false
    @State private var editingField: EditField? = nil

    enum EditField { case hours, mins }

    private var hours: Int { selectedMinutes / 60 }
    private var mins: Int { selectedMinutes % 60 }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 1) {
            DigitCell(
                displayValue: hours,
                maxValue: 99,
                isEditing: editingField == .hours,
                onTap: { editingField = .hours },
                onCommit: { newVal in
                    selectedMinutes = newVal * 60 + mins
                    editingField = nil
                },
                onCancel: { editingField = nil }
            )
            Text("H")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(white: 0.35))
            Spacer().frame(width: 6)
            DigitCell(
                displayValue: mins,
                maxValue: 59,
                isEditing: editingField == .mins,
                onTap: { editingField = .mins },
                onCommit: { newVal in
                    selectedMinutes = hours * 60 + min(newVal, 59)
                    editingField = nil
                },
                onCancel: { editingField = nil }
            )
            Text("M")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(white: 0.35))
        }
        .onChange(of: dismissTrigger) { _ in
            editingField = nil
        }
    }

    func dismissEditing() {
        editingField = nil
    }
}


// MARK: - Digit cell (label / text field)

struct DigitCell: View {
    let displayValue: Int
    let maxValue: Int
    let isEditing: Bool
    let onTap: () -> Void
    let onCommit: (Int) -> Void
    let onCancel: () -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            if !isEditing {
                Text(String(format: "%02d", displayValue))
                    .font(.system(size: 28, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 40, alignment: .trailing)
                    .contentShape(Rectangle())
                    .onTapGesture { onTap() }
            }

            if isEditing {
                TextField("00", text: $text)
                    .font(.system(size: 28, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 40)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onAppear {
                        text = String(format: "%02d", displayValue)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isFocused = true
                        }
                    }
                    .onChange(of: text) { newVal in
                        let digits = String(newVal.filter(\.isNumber).prefix(2))
                        if digits != newVal { text = digits }
                    }
                    .onChange(of: isFocused) { focused in
                        if !focused {
                            let n = min(Int(text) ?? 0, maxValue)
                            onCommit(max(0, n))
                        }
                    }
                    .onSubmit { isFocused = false }
            }
        }
    }
}

// MARK: - Horizontal Tick Slider (with haptic feedback every 5 min)

struct HorizontalTickSlider: View {
    @Binding var minutes: Int

    private let minM = 1.0
    private let maxM = 120.0

    private var fraction: CGFloat {
        CGFloat(max(0, min(1, (Double(minutes) - minM) / (maxM - minM))))
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .leading) {
                Canvas { ctx, size in
                    let totalTicks = 120
                    for i in 0...totalTicks {
                        let x = CGFloat(i) / CGFloat(totalTicks) * size.width
                        let isMajor  = i % 30 == 0
                        let isMedium = i % 15 == 0
                        let isMinor5 = i % 5 == 0
                        let tickH: CGFloat = isMajor  ? size.height * 0.65
                                           : isMedium ? size.height * 0.4
                                           : isMinor5 ? size.height * 0.28
                                           : size.height * 0.15
                        let y = (size.height - tickH) / 2
                        let alpha: CGFloat = isMajor ? 0.5 : isMedium ? 0.3 : isMinor5 ? 0.2 : 0.08

                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x, y: y + tickH))
                        ctx.stroke(path,
                                   with: .color(.white.opacity(Double(alpha))),
                                   lineWidth: 0.6)
                    }
                }
                .frame(width: w, height: h)

                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white)
                    .frame(width: 2, height: h * 0.85)
                    .offset(x: fraction * w - 1)
                    .animation(.interactiveSpring(response: 0.18, dampingFraction: 0.8), value: minutes)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        let f = max(0, min(1, Double(v.location.x / w)))
                        let raw = Int((minM + f * (maxM - minM)).rounded())
                        if raw != minutes {
                            if raw % 5 == 0 {
                                NSHapticFeedbackManager.defaultPerformer.perform(
                                    .alignment, performanceTime: .now
                                )
                            }
                            minutes = raw
                        }
                    }
            )
        }
    }
}
