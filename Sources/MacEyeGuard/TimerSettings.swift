import Foundation

struct TimerSettings: Equatable {
    var workSeconds: Int
    var shortBreakSeconds: Int
    var longBreakSeconds: Int
    var longBreakInterval: Int

    static let `default` = TimerSettings(
        workSeconds: 20 * 60,
        shortBreakSeconds: 20,
        longBreakSeconds: 5 * 60,
        longBreakInterval: 3
    )

    var safeWorkSeconds: Int { max(1, workSeconds) }
    var safeShortBreakSeconds: Int { max(1, shortBreakSeconds) }
    var safeLongBreakSeconds: Int { max(1, longBreakSeconds) }
    var safeLongBreakInterval: Int { max(1, longBreakInterval) }
}

enum SettingsKeys {
    static let workSeconds = "workSeconds"
    static let shortBreakSeconds = "shortBreakSeconds"
    static let longBreakSeconds = "longBreakSeconds"
    static let longBreakInterval = "longBreakInterval"
}
