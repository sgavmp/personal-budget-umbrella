import SwiftUI

/// A pair of date pickers for selecting a date range (from / to).
struct DateRangePicker: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?

    @State private var startEnabled = false
    @State private var endEnabled   = false
    @State private var localStart   = Date()
    @State private var localEnd     = Date()

    var body: some View {
        Group {
            Toggle(isOn: $startEnabled) {
                Text("from_date")
            }
            .onChange(of: startEnabled) { _, enabled in
                startDate = enabled ? localStart : nil
            }

            if startEnabled {
                DatePicker("", selection: $localStart, displayedComponents: .date)
                    .labelsHidden()
                    .onChange(of: localStart) { _, d in
                        startDate = d
                        // Ensure end is not before start
                        if let end = endDate, end < d {
                            localEnd = d
                            endDate  = d
                        }
                    }
            }

            Toggle(isOn: $endEnabled) {
                Text("to_date")
            }
            .onChange(of: endEnabled) { _, enabled in
                endDate = enabled ? localEnd : nil
            }

            if endEnabled {
                DatePicker(
                    "",
                    selection: $localEnd,
                    in: localStart...,
                    displayedComponents: .date
                )
                .labelsHidden()
                .onChange(of: localEnd) { _, d in endDate = d }
            }
        }
    }
}

#Preview {
    @Previewable @State var start: Date? = nil
    @Previewable @State var end: Date?   = nil
    Form {
        DateRangePicker(startDate: $start, endDate: $end)
    }
}
