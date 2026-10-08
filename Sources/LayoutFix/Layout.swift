enum Script { case latin, hebrew }

enum Layout {
    // US QWERTY key -> what the macOS "Hebrew" layout types on the same physical key.
    static let enToHe: [Character: Character] = [
        "q": "/", "w": "׳", "e": "ק", "r": "ר", "t": "א", "y": "ט", "u": "ו", "i": "ן", "o": "ם", "p": "פ",
        "a": "ש", "s": "ד", "d": "ג", "f": "כ", "g": "ע", "h": "י", "j": "ח", "k": "ל", "l": "ך", ";": "ף", "'": ",",
        "z": "ז", "x": "ס", "c": "ב", "v": "ה", "b": "נ", "n": "מ", "m": "צ", ",": "ת", ".": "ץ", "/": ".",
    ]
    static let heToEn = Dictionary(uniqueKeysWithValues: enToHe.map { ($1, $0) })

    static func convert(_ s: String, _ map: [Character: Character]) -> String? {
        var out = ""
        for c in s {
            guard let m = map[c] else { return nil }
            out.append(m)
        }
        return out
    }

    /// The word the user meant, if `word` was typed in the wrong layout.
    /// Only fires when the typed word is not a word but its conversion is.
    static func fix(_ word: String, valid: (String, String) -> Bool) -> (text: String, to: Script)? {
        guard word.count >= 2 else { return nil }
        if word.unicodeScalars.contains(where: { (0x05D0...0x05EA).contains($0.value) }) {
            guard let en = convert(word, heToEn), !valid(word, "he"), valid(en, "en") else { return nil }
            return (en, .latin)
        }
        guard let he = convert(word.lowercased(), enToHe), !valid(word, "en"), valid(he, "he") else { return nil }
        return (he, .hebrew)
    }

    /// The previous word, converted to `script`, when the word after it just got fixed into
    /// `script` and the conversion is a real word. Catches words that are valid in both
    /// languages and so were left alone on their own (`tbh` before `tuvc` -> `אני אוהב`).
    static func retro(_ prev: String, to script: Script, valid: (String, String) -> Bool) -> String? {
        let isHebrew = prev.unicodeScalars.contains { (0x05D0...0x05EA).contains($0.value) }
        let converted: String?
        switch script {
        case .hebrew: converted = isHebrew ? nil : convert(prev.lowercased(), enToHe)
        case .latin: converted = isHebrew ? convert(prev, heToEn) : nil
        }
        guard let converted, valid(converted, script == .hebrew ? "he" : "en") else { return nil }
        return converted
    }
}

func selftest() {
    let words: [String: Set<String>] = ["en": ["check", "why", "want", "tbh", "i"], "he": ["תהיה", "שלום", "אני", "אוהב"]]
    let valid = { (w: String, lang: String) in words[lang]!.contains(w) }
    func check(_ input: String, _ want: (String, Script)?) {
        let got = Layout.fix(input, valid: valid)
        precondition(got?.text == want?.0 && got?.to == want?.1, "\(input): got \(String(describing: got))")
    }
    check("ביקבל", ("check", .latin))
    check("׳יט", ("why", .latin))
    check(",vhv", ("תהיה", .hebrew))
    check("AKUO", ("שלום", .hebrew))
    check("check", nil)     // already a word
    check("שלום", nil)      // already a word
    check("x", nil)         // too short to judge
    check("hello2", nil)    // digit has no mapping
    // "אני אוהב" typed in English: "tbh" is valid English on its own, fixed once "tuvc" is
    check("tbh", nil)
    check("tuvc", ("אוהב", .hebrew))
    precondition(Layout.retro("tbh", to: .hebrew, valid: valid) == "אני")
    precondition(Layout.retro("ן", to: .latin, valid: valid) == "i")
    precondition(Layout.retro("want", to: .hebrew, valid: valid) == nil)  // no Hebrew reading
    precondition(Layout.retro("אני", to: .hebrew, valid: valid) == nil)   // already Hebrew
    print("selftest ok")
}
