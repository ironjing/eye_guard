import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let timerManager = EyeCareTimerManager()
    private var statusItem: NSStatusItem?
    private let statusMenu = NSMenu()
    private var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    private var startPauseItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupMenu()
        bindUpdates()
        refreshUI()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Eye Guard")
            button.imagePosition = .imageLeft
            button.title = timerManager.menuBarCountdownText
            button.toolTip = "Eye Guard"
        }
        item.menu = statusMenu
        statusItem = item
    }

    private func setupMenu() {
        let startPause = NSMenuItem(
            title: "暂停",
            action: #selector(toggleStartPause),
            keyEquivalent: ""
        )
        startPause.target = self
        startPause.image = NSImage(systemSymbolName: "pause.circle", accessibilityDescription: nil)
        startPauseItem = startPause
        statusMenu.addItem(startPause)

        let reset = NSMenuItem(
            title: "重置",
            action: #selector(resetTimer),
            keyEquivalent: ""
        )
        reset.target = self
        reset.image = NSImage(systemSymbolName: "arrow.counterclockwise", accessibilityDescription: nil)
        statusMenu.addItem(reset)

        let skip = NSMenuItem(
            title: "跳过当前阶段",
            action: #selector(skipPhase),
            keyEquivalent: ""
        )
        skip.target = self
        skip.image = NSImage(systemSymbolName: "forward.end", accessibilityDescription: nil)
        statusMenu.addItem(skip)

        statusMenu.addItem(.separator())

        let settings = NSMenuItem(
            title: "设置",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settings.target = self
        settings.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        statusMenu.addItem(settings)

        statusMenu.addItem(.separator())

        let quit = NSMenuItem(
            title: "退出 Eye Guard",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quit.target = self
        quit.image = NSImage(systemSymbolName: "xmark.square", accessibilityDescription: nil)
        statusMenu.addItem(quit)
    }

    private func bindUpdates() {
        timerManager.$phase
            .combineLatest(timerManager.$remainingSeconds, timerManager.$isRunning)
            .sink { [weak self] _, _, _ in
                self?.refreshUI()
            }
            .store(in: &cancellables)

        timerManager.$settings
            .sink { [weak self] _ in
                self?.refreshUI()
            }
            .store(in: &cancellables)
    }

    private func refreshUI() {
        if let button = statusItem?.button {
            button.title = timerManager.menuBarCountdownText
        }

        guard let startPauseItem else { return }
        if timerManager.isRunning {
            startPauseItem.title = "暂停"
            startPauseItem.image = NSImage(systemSymbolName: "pause.circle", accessibilityDescription: nil)
        } else {
            startPauseItem.title = "开始"
            startPauseItem.image = NSImage(systemSymbolName: "play.circle", accessibilityDescription: nil)
        }
    }

    @objc private func toggleStartPause() {
        if timerManager.isRunning {
            timerManager.pause()
        } else {
            timerManager.start()
        }
    }

    @objc private func resetTimer() {
        timerManager.reset()
        refreshUI()
    }

    @objc private func skipPhase() {
        timerManager.skipCurrentPhase()
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let view = SettingsView().environmentObject(timerManager)
            let hostingController = NSHostingController(rootView: view)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "设置"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 680, height: 500))
            window.minSize = NSSize(width: 620, height: 440)
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
