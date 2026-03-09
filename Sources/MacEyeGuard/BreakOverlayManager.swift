import AppKit
import SwiftUI

@MainActor
final class BreakOverlayManager {
    private var windows: [NSWindow] = []

    func showBreakOverlay(phase: TimerPhase, remainingSeconds: Int, onEndEarly: @escaping () -> Void) {
        hideAllOverlays()

        for screen in NSScreen.screens {
            let hosting = NSHostingView(
                rootView: BreakOverlayView(
                    phase: phase,
                    remainingSeconds: remainingSeconds,
                    onEndEarly: onEndEarly
                )
            )

            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = .screenSaver
            window.backgroundColor = .black
            window.isOpaque = true
            window.hasShadow = false
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.contentView = hosting
            window.setFrame(screen.frame, display: true)
            window.makeKeyAndOrderFront(nil)

            windows.append(window)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    func updateContent(phase: TimerPhase, remainingSeconds: Int, onEndEarly: @escaping () -> Void) {
        for window in windows {
            guard let hosting = window.contentView as? NSHostingView<BreakOverlayView> else { continue }
            hosting.rootView = BreakOverlayView(
                phase: phase,
                remainingSeconds: remainingSeconds,
                onEndEarly: onEndEarly
            )
        }
    }

    func updateCountdown(_ remainingSeconds: Int) {
        for window in windows {
            guard let hosting = window.contentView as? NSHostingView<BreakOverlayView> else { continue }
            let current = hosting.rootView
            hosting.rootView = BreakOverlayView(
                phase: current.phase,
                remainingSeconds: remainingSeconds,
                onEndEarly: current.onEndEarly
            )
        }
    }

    func hideAllOverlays() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }
}

struct BreakOverlayView: View {
    let phase: TimerPhase
    var remainingSeconds: Int
    let onEndEarly: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text(phase == .longBreak ? "长休息中" : "短休息中")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.gray)

                Text(EyeCareTimerManager.format(seconds: remainingSeconds))
                    .font(.system(size: 72, weight: .semibold, design: .monospaced))
                    .foregroundColor(.gray)

                Button(action: onEndEarly) {
                    Text("已休息好")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .controlSize(.large)
            }
            .padding(40)
        }
    }
}
