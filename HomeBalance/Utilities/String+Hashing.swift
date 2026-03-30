import CryptoKit
import Foundation

extension String {

    // MARK: - SHA-256 for deduplication

    /// Returns the SHA-256 hex digest of the string (UTF-8 encoded).
    /// Used for composite import-hash keys: `date + amount + description`.
    var sha256: String {
        let data = Data(utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Levenshtein distance for fuzzy dedup

    /// Normalised Levenshtein similarity in [0, 1].
    /// 1.0 = identical strings, 0.0 = completely different.
    func similarity(to other: String) -> Double {
        let distance = levenshteinDistance(to: other)
        let maxLen = max(count, other.count)
        guard maxLen > 0 else { return 1.0 }
        return 1.0 - Double(distance) / Double(maxLen)
    }

    // MARK: - Normalisation helpers

    /// Lowercased, trimmed, with runs of whitespace collapsed to a single space.
    var normalised: String {
        lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    // MARK: - Private

    private func levenshteinDistance(to other: String) -> Int {
        let a = Array(self)
        let b = Array(other)
        var matrix = [[Int]](
            repeating: [Int](repeating: 0, count: b.count + 1),
            count: a.count + 1
        )

        for i in 0...a.count { matrix[i][0] = i }
        for j in 0...b.count { matrix[0][j] = j }

        for i in 1...a.count {
            for j in 1...b.count {
                if a[i - 1] == b[j - 1] {
                    matrix[i][j] = matrix[i - 1][j - 1]
                } else {
                    matrix[i][j] = 1 + Swift.min(
                        matrix[i - 1][j],     // deletion
                        Swift.min(
                            matrix[i][j - 1],     // insertion
                            matrix[i - 1][j - 1]  // substitution
                        )
                    )
                }
            }
        }

        return matrix[a.count][b.count]
    }
}
