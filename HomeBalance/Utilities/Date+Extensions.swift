import Foundation

extension Date {

    // MARK: - Month / Year helpers

    var year: Int  { Calendar.current.component(.year,  from: self) }
    var month: Int { Calendar.current.component(.month, from: self) }
    var day: Int   { Calendar.current.component(.day,   from: self) }

    /// Returns (year, month) tuple for use in Budget keys.
    var yearMonth: (year: Int, month: Int) { (year, month) }

    /// First day of the month at midnight.
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// Last moment of the last day of the month.
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    /// Same month and year as `other`.
    func isSameMonth(as other: Date) -> Bool {
        year == other.year && month == other.month
    }

    // MARK: - Relative helpers

    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    // MARK: - Parsing

    /// Attempts to parse a date string using the provided format.
    /// - Parameters:
    ///   - string: The raw string from a CSV/Excel cell.
    ///   - format: Date format, e.g. "dd/MM/yyyy" or "yyyy-MM-dd".
    ///   - locale: Locale to use (affects month names in textual formats).
    static func parse(_ string: String, format: String, locale: Locale = Locale(identifier: "es_ES")) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = locale
        formatter.timeZone = TimeZone(identifier: "Europe/Madrid")
        return formatter.date(from: string.trimmingCharacters(in: .whitespaces))
    }

    // MARK: - Display

    /// Short date string: "12 ene 2025"
    var shortDisplay: String {
        formatted(.dateTime.day().month(.abbreviated).year())
    }

    /// Month + year: "enero 2025"
    var monthYearDisplay: String {
        formatted(.dateTime.month(.wide).year())
    }
}
