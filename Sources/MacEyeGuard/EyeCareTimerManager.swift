import AppKit
import Combine
import Foundation

enum TimerPhase: Equatable {
    case working
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .working: return "工作中"
        case .shortBreak: return "短休息"
        case .longBreak: return "长休息"
        }
    }

    var isBreak: Bool {
        switch self {
        case .working: return false
        case .shortBreak, .longBreak: return true
        }
    }
}

@MainActor
final class EyeCareTimerManager: ObservableObject {
    @Published var settings: TimerSettings
    @Published var phase: TimerPhase = .working
    @Published var remainingSeconds: Int = TimerSettings.default.workSeconds
    @Published var completedShortBreaks: Int = 0
    @Published var isRunning: Bool = false

    private var ticker: AnyCancellable?
    private let defaults: UserDefaults
    private let overlayManager = BreakOverlayManager()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let work = defaults.object(forKey: SettingsKeys.workSeconds) as? Int ?? TimerSettings.default.workSeconds
        let shortBreak = defaults.object(forKey: SettingsKeys.shortBreakSeconds) as? Int ?? TimerSettings.default.shortBreakSeconds
        let longBreak = defaults.object(forKey: SettingsKeys.longBreakSeconds) as? Int ?? TimerSettings.default.longBreakSeconds
        let interval = defaults.object(forKey: SettingsKeys.longBreakInterval) as? Int ?? TimerSettings.default.longBreakInterval

        let initial = TimerSettings(
            workSeconds: work,
            shortBreakSeconds: shortBreak,
            longBreakSeconds: longBreak,
            longBreakInterval: interval
        )

        self.settings = initial
        self.remainingSeconds = initial.safeWorkSeconds

        // Auto-start timer when app launches.
        start()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        startTicker()
    }

    func pause() {
        isRunning = false
        ticker?.cancel()
        ticker = nil
    }

    func reset() {
        let wasRunning = isRunning
        pause()
        phase = .working
        remainingSeconds = settings.safeWorkSeconds
        completedShortBreaks = 0
        overlayManager.hideAllOverlays()
        if wasRunning {
            start()
        }
    }

    func skipCurrentPhase() {
        transitionToNextPhase()
    }

    func endBreakEarly() {
        guard phase.isBreak else { return }
        transitionToNextPhase()
    }

    func applySettings(_ newSettings: TimerSettings) {
        let normalized = TimerSettings(
            workSeconds: newSettings.safeWorkSeconds,
            shortBreakSeconds: newSettings.safeShortBreakSeconds,
            longBreakSeconds: newSettings.safeLongBreakSeconds,
            longBreakInterval: newSettings.safeLongBreakInterval
        )

        settings = normalized
        persistSettings(normalized)

        if phase == .working {
            remainingSeconds = min(remainingSeconds, normalized.safeWorkSeconds)
        } else if phase == .shortBreak {
            remainingSeconds = min(remainingSeconds, normalized.safeShortBreakSeconds)
        } else {
            remainingSeconds = min(remainingSeconds, normalized.safeLongBreakSeconds)
        }

        if remainingSeconds <= 0 {
            remainingSeconds = seconds(for: phase)
        }

        if phase.isBreak {
            overlayManager.updateContent(phase: phase, remainingSeconds: remainingSeconds, onEndEarly: { [weak self] in
                self?.endBreakEarly()
            })
        }
    }

    var phaseProgressText: String {
        "\(phase.title) · 剩余 \(Self.format(seconds: remainingSeconds))"
    }

    var menuBarCountdownText: String {
        let workSeconds = phase == .working ? remainingSeconds : settings.safeWorkSeconds
        return "工 \(Self.format(seconds: workSeconds))"
    }

    static func format(seconds: Int) -> String {
        let minute = seconds / 60
        let second = seconds % 60
        return String(format: "%02d:%02d", minute, second)
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard isRunning else { return }

        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }

        if phase.isBreak {
            overlayManager.updateCountdown(remainingSeconds)
        }

        if remainingSeconds == 0 {
            transitionToNextPhase()
        }
    }

    private func transitionToNextPhase() {
        switch phase {
        case .working:
            let next: TimerPhase
            if (completedShortBreaks + 1) % settings.safeLongBreakInterval == 0 {
                next = .longBreak
            } else {
                next = .shortBreak
            }
            phase = next
            remainingSeconds = seconds(for: next)
            overlayManager.showBreakOverlay(
                phase: next,
                remainingSeconds: remainingSeconds,
                onEndEarly: { [weak self] in
                    self?.endBreakEarly()
                }
            )
            if !isRunning {
                start()
            }

        case .shortBreak:
            completedShortBreaks += 1
            phase = .working
            remainingSeconds = settings.safeWorkSeconds
            overlayManager.hideAllOverlays()

        case .longBreak:
            completedShortBreaks += 1
            phase = .working
            remainingSeconds = settings.safeWorkSeconds
            overlayManager.hideAllOverlays()
        }
    }

    private func seconds(for phase: TimerPhase) -> Int {
        switch phase {
        case .working:
            return settings.safeWorkSeconds
        case .shortBreak:
            return settings.safeShortBreakSeconds
        case .longBreak:
            return settings.safeLongBreakSeconds
        }
    }

    private func persistSettings(_ settings: TimerSettings) {
        defaults.set(settings.safeWorkSeconds, forKey: SettingsKeys.workSeconds)
        defaults.set(settings.safeShortBreakSeconds, forKey: SettingsKeys.shortBreakSeconds)
        defaults.set(settings.safeLongBreakSeconds, forKey: SettingsKeys.longBreakSeconds)
        defaults.set(settings.safeLongBreakInterval, forKey: SettingsKeys.longBreakInterval)
    }
}
