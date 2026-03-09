import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var timerManager: EyeCareTimerManager

    @State private var workMinutes: Double = 20
    @State private var shortBreakSeconds: Double = 20
    @State private var longBreakMinutes: Double = 5
    @State private var longBreakInterval: Double = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("护眼设置")
                .font(.system(size: 28, weight: .bold))

            Text("建议保持 20-20-20 规则，可按你的工作节奏微调。")
                .foregroundColor(.secondary)

            SettingRow(
                title: "工作时长",
                subtitle: "专注阶段时长（分钟）",
                value: $workMinutes,
                range: 1...180,
                step: 1,
                unit: "分钟"
            ) { apply() }

            SettingRow(
                title: "短休时长",
                subtitle: "每次短休息时长（秒）",
                value: $shortBreakSeconds,
                range: 5...600,
                step: 1,
                unit: "秒"
            ) { apply() }

            SettingRow(
                title: "长休时长",
                subtitle: "每次长休息时长（分钟）",
                value: $longBreakMinutes,
                range: 1...60,
                step: 1,
                unit: "分钟"
            ) { apply() }

            SettingRow(
                title: "长休间隔",
                subtitle: "每隔几次进入长休",
                value: $longBreakInterval,
                range: 1...20,
                step: 1,
                unit: "次"
            ) { apply() }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(minWidth: 620, minHeight: 440, alignment: .topLeading)
        .onAppear {
            syncFromManager()
        }
    }

    private func syncFromManager() {
        let s = timerManager.settings
        workMinutes = Double(s.workSeconds) / 60
        shortBreakSeconds = Double(s.shortBreakSeconds)
        longBreakMinutes = Double(s.longBreakSeconds) / 60
        longBreakInterval = Double(s.longBreakInterval)
    }

    private func apply() {
        let newValue = TimerSettings(
            workSeconds: Int(workMinutes * 60),
            shortBreakSeconds: Int(shortBreakSeconds),
            longBreakSeconds: Int(longBreakMinutes * 60),
            longBreakInterval: Int(longBreakInterval)
        )
        timerManager.applySettings(newValue)
    }
}

private struct SettingRow: View {
    let title: String
    let subtitle: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let onChanged: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(Int(value)) \(unit)")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .frame(minWidth: 120, alignment: .trailing)

            Stepper("", value: $value, in: range, step: step)
                .labelsHidden()
                .onChange(of: value) { _ in onChanged() }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}
