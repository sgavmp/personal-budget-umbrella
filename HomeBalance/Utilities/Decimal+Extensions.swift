import Foundation

extension Decimal {

    // MARK: - Formatting

    /// Returns a localised currency string for the given ISO 4217 currency code.
    /// Example: `Decimal("1234.50").formatted(currency: "EUR")` → "1.234,50 €"
    func formatted(currency: String, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = locale
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }

    /// Returns a plain decimal string with exactly `places` fractional digits.
    func formatted(places: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = places
        formatter.maximumFractionDigits = places
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }

    // MARK: - Rounding

    /// Rounds to `places` decimal places using bankers rounding (IEEE 754).
    func rounded(toPlaces places: Int = 2) -> Decimal {
        var result = Decimal()
        var mutableSelf = self
        NSDecimalRound(&result, &mutableSelf, places, .bankers)
        return result
    }

    // MARK: - Sign helpers

    var isPositive: Bool { self > 0 }
    var isNegative: Bool { self < 0 }

    var absoluteValue: Decimal { self < 0 ? -self : self }

    // MARK: - Parsing

    /// Parses a monetary string that may use comma or dot as decimal separator.
    /// Handles cases like "1.234,56", "1,234.56", "-45,00", "45.00".
    static func parse(_ string: String, decimalSeparator: Character = ".") -> Decimal? {
        var s = string.trimmingCharacters(in: .whitespaces)

        // Determine the thousands separator (the opposite of decimal separator)
        let thousandsSeparator: Character = decimalSeparator == "." ? "," : "."

        // Remove thousands separators first
        s = s.replacingOccurrences(of: String(thousandsSeparator), with: "")

        // Normalise decimal separator to "."
        if decimalSeparator == "," {
            s = s.replacingOccurrences(of: ",", with: ".")
        }

        return Decimal(string: s)
    }
}
