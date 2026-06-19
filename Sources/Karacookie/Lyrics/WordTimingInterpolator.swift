import Foundation

struct WordTiming: Equatable {
    let text: String   // may be a whitespace run (no highlight) or a word token
    let startMs: Int
    let endMs: Int

    var isWhitespace: Bool { text.allSatisfy { $0.isWhitespace } }
}

enum WordTimingInterpolator {
    private static let functionWords: Set<String> = [
        "the", "a", "an", "to", "of", "in", "and", "or", "but", "for",
        "with", "on", "at", "by", "from", "as", "is", "it", "be", "are",
        "was", "were", "i", "you", "he", "she", "we", "they", "my", "your"
    ]

    /// Allocate per-word [start, end] windows across the line duration,
    /// weighted by word length (function words 0.6×, content words 1.0×).
    static func interpolate(text: String, startMs: Int, endMs: Int) -> [WordTiming] {
        let duration = max(1, endMs - startMs)
        let tokens = tokenize(text)
        guard !tokens.isEmpty else { return [] }

        let weights: [Double] = tokens.map { tok in
            if tok.allSatisfy({ $0.isWhitespace }) { return 0 }
            let normalized = tok.lowercased().filter { $0.isLetter }
            let baseWeight = max(1.0, Double(normalized.count))
            return functionWords.contains(normalized) ? baseWeight * 0.6 : baseWeight
        }
        let totalWeight = weights.reduce(0, +)
        guard totalWeight > 0 else {
            return tokens.map { WordTiming(text: $0, startMs: startMs, endMs: endMs) }
        }

        var t = 0.0
        var out: [WordTiming] = []
        out.reserveCapacity(tokens.count)
        for (i, tok) in tokens.enumerated() {
            let frac = weights[i] / totalWeight
            let s = startMs + Int(t * Double(duration))
            t += frac
            let e = startMs + Int(t * Double(duration))
            out.append(WordTiming(text: tok, startMs: s, endMs: e))
        }
        return out
    }

    /// Split into alternating word / whitespace tokens so HStack rendering preserves layout.
    private static func tokenize(_ s: String) -> [String] {
        var out: [String] = []
        var current = ""
        var inWhitespace = false
        for ch in s {
            let isWS = ch.isWhitespace
            if current.isEmpty {
                current.append(ch); inWhitespace = isWS
            } else if isWS == inWhitespace {
                current.append(ch)
            } else {
                out.append(current); current = String(ch); inWhitespace = isWS
            }
        }
        if !current.isEmpty { out.append(current) }
        return out
    }
}
