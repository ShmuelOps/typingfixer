import AppKit
import ServiceManagement

if CommandLine.arguments.contains("--selftest") {
    selftest()
    exit(0)
}

final class App: NSObject, NSApplicationDelegate {
    let typist = Typist()
    var item: NSStatusItem!

    func applicationDidFinishLaunching(_ note: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = menuIcon()
        item.button?.imagePosition = .imageLeading
        let menu = NSMenu()
        let toggle = NSMenuItem(title: "Enabled", action: #selector(toggle(_:)), keyEquivalent: "")
        toggle.target = self
        toggle.state = .on
        menu.addItem(toggle)
        let sound = NSMenuItem(title: "Play sound on swap", action: #selector(toggleSound(_:)), keyEquivalent: "")
        sound.target = self
        sound.state = .on
        menu.addItem(sound)
        let login = NSMenuItem(title: "Launch at login", action: #selector(toggleLogin(_:)), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit TypingFixer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu

        let prompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(prompt)
        startWhenTrusted()
    }

    /// The event tap can't be created until Accessibility is granted; retry until it is.
    func startWhenTrusted() {
        if AXIsProcessTrusted() && typist.start() {
            item.button?.title = ""
            item.button?.toolTip = "TypingFixer"
            return
        }
        item.button?.title = "!"
        item.button?.toolTip = "TypingFixer needs Accessibility permission"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.startWhenTrusted() }
    }

    @objc func toggleLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSAlert(error: error).runModal()
        }
        sender.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc func toggleSound(_ sender: NSMenuItem) {
        typist.sound.toggle()
        sender.state = typist.sound ? .on : .off
    }

    @objc func toggle(_ sender: NSMenuItem) {
        typist.enabled.toggle()
        sender.state = typist.enabled ? .on : .off
        item.button?.appearsDisabled = !typist.enabled
    }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
