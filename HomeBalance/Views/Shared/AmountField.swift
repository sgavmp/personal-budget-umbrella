import SwiftUI

/// A text field specialised for monetary input.
/// Shows a currency symbol prefix and validates on-the-fly.
struct AmountField: View {
    let label: LocalizedStringKey
    @Binding var text: String
    var currency: String = "EUR"
    var placeholder: String = "0.00"

    @State private var isValid = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(currencySymbol)
                    .foregroundStyle(.secondary)
                    .font(.body.weight(.medium))

                TextField(placeholder, text: $text)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .onChange(of: text) { _, newValue in
                        isValid = validate(newValue)
                    }
            }
            .padding(10)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isValid ? Color.secondary.opacity(0.3) : Color.red, lineWidth: 1)
            }

            if !isValid {
                Text("invalid_amount")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

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
}
