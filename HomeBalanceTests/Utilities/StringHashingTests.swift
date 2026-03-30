import Testing
@testable import HomeBalance

@Suite("String+Hashing")
struct StringHashingTests {

    @Test("SHA-256 of the same string is always equal")
    func sha256IsDeterministic() {
        let input = "2024-01-15|42.50|MERCADONA"
        #expect(input.sha256 == input.sha256)
    }

    @Test("SHA-256 of different strings differ")
    func sha256DifferentStrings() {
        let a = "2024-01-15|42.50|MERCADONA"
        let b = "2024-01-15|42.51|MERCADONA"
        #expect(a.sha256 != b.sha256)
    }

    @Test("SHA-256 is a 64-character hex string")
    func sha256Length() {
        #expect("hello".sha256.count == 64)
    }

    @Test("Identical strings have similarity 1.0")
    func similarityIdentical() {
        #expect("MERCADONA".similarity(to: "MERCADONA") == 1.0)
    }

    @Test("Completely different strings have similarity < 0.5")
    func similarityDifferent() {
        let sim = "MERCADONA".similarity(to: "IBERDROLA")
        #expect(sim < 0.5)
    }

    @Test("Similar strings (typo) have similarity > 0.8")
    func similarityTypo() {
        // One character different
        let sim = "MERCADONA".similarity(to: "MERCADONAS")
        #expect(sim > 0.8)
    }

    @Test("Empty strings have similarity 1.0")
    func similarityBothEmpty() {
        #expect("".similarity(to: "") == 1.0)
    }

    @Test("Normalised string is lowercase and trimmed")
    func normalisedString() {
        let input = "  MERCADONA  CALLE  MAYOR  "
        let result = input.normalised
        #expect(result == "mercadona calle mayor")
    }
}
