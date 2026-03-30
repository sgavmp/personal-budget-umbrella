import SwiftUI

/// A text field specialised for monetary input.
/// Design: "The Financial Curator" — currency prefix, inline validation indicator.
struct AmountField: View {
    let label: LocalizedStringKey
    @Binding var text: String
    var currency: String = "EUR"
    var placeholder: String = "0.00"

    @State private var isValid = true

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.xs) {
            HStack(spacing: HBSpacing.sm) {
                // Currency symbol
                Text(currencySymbol)
                    .font(.hbHeadlineMedium)
                    .foregroundStyle(.hbPrimary)

                // Text field
                TextField(placeholder, text: $text)
                    .font(.hbHeadlineMedium)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .onChange(of: text) { _, newValue in
                        isValid = validate(newValue)
                    }
            }
            .padding(.horizontal, HBSpacing.md)
            .padding(.vertical, HBSpacing.sm + 2)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: HBRadius.chip))
            .overlay {
                RoundedRectangle(cornerRadius: HBRadius.chip)
                    .strokeBorder(
                        isValid ? Color.hbSurfaceVariant : Color.hbError,
                        lineWidth: 1.5
                    )
            }

            // Inline error
            if !isValid {
                HStack(spacing: HBSpacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text("invalid_amount")
                        .font(.hbLabelSmall)
                }
                .foregroundStyle(.hbError)
            }
        }
    }

    // MARK: - Helpers

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.currencySymbol ?? currency
    }

    private func validate(_ value: String) -> Bool {
        guard !value.isEmpty else { return true }
        let separators = CharacterSet(charactersIn: ".,")
        let digits = value.unicodeScalars.filter {
            CharacterSet.decimalDigits.union(separators).contains($0)
        }
        return digits.count == value.count
    }
}

#Preview {
    @Previewable @State var amount = ""
    Form {
        AmountField(label: "Amount", text: $amount, currency: "EUR")
    }
    .background(Color.hbSurface)
}
