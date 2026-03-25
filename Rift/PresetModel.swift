import Foundation

struct TimerPreset: Identifiable {
    let id = UUID()
    let minutes: Int
    var label: String { "\(minutes)" }
}

extension TimerPreset {
    static let defaults: [TimerPreset] = [
        TimerPreset(minutes: 5),
        TimerPreset(minutes: 15),
        TimerPreset(minutes: 25),
        TimerPreset(minutes: 45),
        TimerPreset(minutes: 60),
    ]
}
