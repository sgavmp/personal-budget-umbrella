import Testing
import Foundation
@testable import HomeBalance

@Suite("Decimal+Extensions")
struct DecimalExtensionsTests {

    @Test("parse dot-decimal string")
    func parseDotDecimal() {
        let result = Decimal.parse("1234.56", decimalSeparator: ".")
        #expect(result == Decimal(string: "1234.56"))
    }

    @Test("parse comma-decimal string")
    func parseCommaDecimal() {
        let result = Decimal.parse("1.234,56", decimalSeparator: ",")
        #expect(result == Decimal(string: "1234.56"))
    }

    @Test("parse negative amount")
    func parseNegative() {
        let result = Decimal.parse("-45,00", decimalSeparator: ",")
        #expect(result == Decimal(string: "-45.00"))
    }

    @Test("parse returns nil for non-numeric string")
    func parseInvalid() {
        let result = Decimal.parse("not a number")
        #expect(result == nil)
    }

    @Test("isNegative")
    func isNegativeFlag() {
        #expect(Decimal(-10).isNegative)
        #expect(!Decimal(10).isNegative)
    }

    @Test("isPositive")
    func isPositiveFlag() {
        #expect(Decimal(10).isPositive)
        #expect(!Decimal(-10).isPositive)
    }

    @Test("absoluteValue returns positive")
    func absoluteValue() {
        #expect(Decimal(-42).absoluteValue == Decimal(42))
    }

    @Test("rounded to 2 places")
    func roundedTwoPlaces() {
        let val = Decimal(string: "1.235")!
        let rounded = val.rounded(toPlaces: 2)
        // Bankers rounding: 1.235 → 1.24 (round half to even)
        #expect(rounded == Decimal(string: "1.24"))
    }
}
