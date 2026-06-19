import Foundation

struct LRCLine: Equatable {
    let timeMs: Int
    let text: String
}

enum LRCParser {
    private static let stampPattern: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"\[(\d+):(\d+)(?:\.(\d+))?\]"#)
    }()

    /// Parses `.lrc` content. Supports multi-timestamp lines and 2- or 3-digit fractional seconds.
    static func parse(_ lrc: String) -> [LRCLine] {
        var lines: [LRCLine] = []
        for raw in lrc.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            let line = String(raw)
            let ns = line as NSString
            let range = NSRange(location: 0, length: ns.length)
            let matches = stampPattern.matches(in: line, range: range)
            guard !matches.isEmpty else { continue }

            let textStart = matches.last!.range.location + matches.last!.range.length
            let textNS = ns.substring(from: textStart)
            let text = textNS.trimmingCharacters(in: .whitespaces)

            for m in matches {
                let mm = Int(ns.substring(with: m.range(at: 1))) ?? 0
                let ss = Int(ns.substring(with: m.range(at: 2))) ?? 0
                let csRange = m.range(at: 3)
                let frac: Int = {
                    guard csRange.location != NSNotFound else { return 0 }
                    let s = ns.substring(with: csRange)
                    let n = Int(s) ?? 0
                    return s.count >= 3 ? n : n * 10   // centiseconds → ms
                }()
                let timeMs = mm * 60_000 + ss * 1000 + frac
                lines.append(LRCLine(timeMs: timeMs, text: text))
            }
        }
        return lines.sorted { $0.timeMs < $1.timeMs }
    }
}
