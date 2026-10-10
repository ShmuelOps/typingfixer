import AppKit
import Carbon

/// Watches keystrokes, and when a finished word was typed in the wrong layout,
/// retypes it in the right one and switches the input source.
/// Keystrokes live only in `tracker` (the current and previous word); nothing is logged or written to disk.
final class Typist {
    static let marker: Int64 = 0x4C46_4958 // tags events we post, so we skip them
    var enabled = true
    var sound = true
    private var tracker = Tracker()
    private var tap: CFMachPort?

    func start() -> Bool {
        if tap != nil { return true }
        let mask = [CGEventType.keyDown, .leftMouseDown, .rightMouseDown].reduce(0) { $0 | (1 << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, ctx in
                Unmanaged<Typist>.fromOpaque(ctx!).takeUnretainedValue().handle(type, event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }
        self.tap = tap
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
        return true
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        let pass = Unmanaged.passUnretained(event)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return pass
        }
        guard enabled, type == .keyDown, !IsSecureEventInputEnabled(),
              event.getIntegerValueField(.eventSourceUserData) != Self.marker,
              event.flags.isDisjoint(with: [.maskCommand, .maskControl, .maskAlternate])
        else {
            if event.getIntegerValueField(.eventSourceUserData) != Self.marker { tracker.reset() }
            return pass
        }

        switch event.getIntegerValueField(.keyboardEventKeycode) {
        case 51: // delete
            tracker.backspace()
            return pass
        case 49, 36, 48, 76: // space, return, tab, keypad enter
            let isSpace = event.getIntegerValueField(.keyboardEventKeycode) == 49
            guard let fix = tracker.delimiter(isSpace: isSpace, valid: isWord) else { return pass }
            for _ in 0..<fix.erase { post(51) }
            for ch in fix.text { post(0, String(ch)) }
            // Swallow the delimiter and re-post it, so it lands after the fixed word.
            let delimiter = event.copy()!
            delimiter.setIntegerValueField(.eventSourceUserData, value: Self.marker)
            delimiter.post(tap: .cgSessionEventTap)
            select(fix.to)
            if sound { NSSound(named: "Blow")?.play() } // built-in /System/Library/Sounds
            return nil
        default:
            var len = 0
            var buf = [UniChar](repeating: 0, count: 4)
            event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &len, unicodeString: &buf)
            let s = String(utf16CodeUnits: buf, count: len)
            // arrows, escape, function keys etc. move the caret: start over
            if len == 0 || s.unicodeScalars.contains(where: { $0.value < 0x20 || $0.value >= 0xF700 }) { tracker.reset() } else { tracker.type(s) }
            return pass
        }
    }

    private func isWord(_ w: String, _ lang: String) -> Bool {
        NSSpellChecker.shared.checkSpelling(of: w, startingAt: 0, language: lang, wrap: false,
                                            inSpellDocumentWithTag: 0, wordCount: nil).location == NSNotFound
    }

    private func post(_ key: CGKeyCode, _ text: String? = nil) {
        for down in [true, false] {
            guard let e = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: down) else { continue }
            e.flags = []
            if let text {
                let u = Array(text.utf16)
                e.keyboardSetUnicodeString(stringLength: u.count, unicodeString: u)
            }
            e.setIntegerValueField(.eventSourceUserData, value: Self.marker)
            e.post(tap: .cgSessionEventTap)
        }
    }

    private func select(_ script: Script) {
        let lang = script == .hebrew ? "he" : "en"
        let filter = [kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource!,
                      kTISPropertyInputSourceIsSelectCapable: true] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else { return }
        let match = list.first { src in
            guard let p = TISGetInputSourceProperty(src, kTISPropertyInputSourceLanguages) else { return false }
            return (Unmanaged<CFArray>.fromOpaque(p).takeUnretainedValue() as? [String])?.first == lang
        }
        if let match { TISSelectInputSource(match) }
    }
}
