import AppKit

if CommandLine.arguments.contains("--selftest") {
    selftest()
    exit(0)
}

final class App: NSObject, NSApplicationDelegate {
    let typist = Typist()
    var item: NSStatusItem!

    func applicationDidFinishLaunching(_ note: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let icon = NSImage(systemSymbolName: "arrow.left.arrow.right", accessibilityDescription: "LayoutFix")
        icon?.isTemplate = true // follows light/dark menu bar
        item.button?.image = icon
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
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit LayoutFix", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu

        let prompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(prompt)
        startWhenTrusted()
    }

    /// The event tap can't be created until Accessibility is granted; retry until it is.
    func startWhenTrusted() {
        if AXIsProcessTrusted() && typist.start() {
            item.button?.title = ""
            item.button?.toolTip = "LayoutFix"
            return
        }
        item.button?.title = "!"
        item.button?.toolTip = "LayoutFix needs Accessibility permission"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.startWhenTrusted() }
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
