import SwiftUI

struct BatchEditView: View {
    let qsos: [QSOEntry]
    @Environment(\.dismiss) private var dismiss

    // Which fields to update
    @State private var editStationCallsign = false
    @State private var editBand = false
    @State private var editMode = false
    @State private var editRSTSent = false
    @State private var editRSTReceived = false
    @State private var editOperatorName = false
    @State private var editNotes = false

    // New values
    @State private var newStationCallsign = ""
    @State private var newBand = "20m"
    @State private var newMode = "SSB"
    @State private var newRSTSent = "59"
    @State private var newRSTReceived = "59"
    @State private var newOperatorName = ""
    @State private var newNotes = ""

    @State private var showConfirmation = false

    var anyFieldSelected: Bool {
        editStationCallsign || editBand || editMode ||
        editRSTSent || editRSTReceived || editOperatorName || editNotes
    }

    let allBands = ["160m", "80m", "60m", "40m", "30m", "20m", "17m",
                    "15m", "12m", "10m", "6m", "2m", "70cm"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Batch Edit")
                        .font(.headline)
                    Text("Editing \(qsos.count) QSO\(qsos.count == 1 ? "" : "s") — tick fields to update")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            Divider()

            // Fields
            Form {
                Section("Station") {
                    BatchFieldRow(
                        enabled: $editStationCallsign,
                        label: "Station Callsign"
                    ) {
                        TextField("e.g. G0ABC/P", text: $newStationCallsign)
                            .onChange(of: newStationCallsign) { _, v in
                                newStationCallsign = v.uppercased()
                            }
                            .disabled(!editStationCallsign)
                    }
                }

                Section("Band & Mode") {
                    BatchFieldRow(
                        enabled: $editBand,
                        label: "Band"
                    ) {
                        Picker("", selection: $newBand) {
                            ForEach(allBands, id: \.self) { Text($0) }
                        }
                        .disabled(!editBand)
                    }

                    BatchFieldRow(
                        enabled: $editMode,
                        label: "Mode"
                    ) {
                        Picker("", selection: $newMode) {
                            ForEach(BandHelper.commonModes, id: \.self) { Text($0) }
                        }
                        .disabled(!editMode)
                    }
                }

                Section("Signal Reports") {
                    BatchFieldRow(
                        enabled: $editRSTSent,
                        label: "RST Sent"
                    ) {
                        TextField("59", text: $newRSTSent)
                            .disabled(!editRSTSent)
                            .frame(width: 80)
                    }

                    BatchFieldRow(
                        enabled: $editRSTReceived,
                        label: "RST Received"
                    ) {
                        TextField("59", text: $newRSTReceived)
                            .disabled(!editRSTReceived)
                            .frame(width: 80)
                    }
                }

                Section("Additional") {
                    BatchFieldRow(
                        enabled: $editOperatorName,
                        label: "Operator Name"
                    ) {
                        TextField("Optional", text: $newOperatorName)
                            .disabled(!editOperatorName)
                    }

                    BatchFieldRow(
                        enabled: $editNotes,
                        label: "Notes"
                    ) {
                        TextField("Optional", text: $newNotes)
                            .disabled(!editNotes)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            // Footer
            HStack {
                Text(anyFieldSelected
                     ? "Will update \(selectedFieldCount) field\(selectedFieldCount == 1 ? "" : "s") on \(qsos.count) QSO\(qsos.count == 1 ? "" : "s")"
                     : "No fields selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Cancel", role: .cancel) {
                    dismiss()
                }

                Button("Apply") {
                    showConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(!anyFieldSelected)
            }
            .padding()
        }
        .frame(minWidth: 450, minHeight: 500)
        .confirmationDialog(
            "Apply Batch Edit?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Apply to \(qsos.count) QSO\(qsos.count == 1 ? "" : "s")", role: .destructive) {
                applyChanges()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will update \(selectedFieldCount) field\(selectedFieldCount == 1 ? "" : "s") on \(qsos.count) QSO\(qsos.count == 1 ? "" : "s"). This cannot be undone.")
        }
    }

    var selectedFieldCount: Int {
        [editStationCallsign, editBand, editMode,
         editRSTSent, editRSTReceived, editOperatorName, editNotes]
            .filter { $0 }.count
    }

    private func applyChanges() {
        for qso in qsos {
            if editStationCallsign { qso.stationCallsign = newStationCallsign }
            if editBand            { qso.band = newBand }
            if editMode            { qso.mode = newMode }
            if editRSTSent         { qso.rstSent = newRSTSent }
            if editRSTReceived     { qso.rstReceived = newRSTReceived }
            if editOperatorName    { qso.operatorName = newOperatorName }
            if editNotes           { qso.notes = newNotes }
        }
    }
}

// MARK: - Batch Field Row

struct BatchFieldRow<Content: View>: View {
    @Binding var enabled: Bool
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            Toggle("", isOn: $enabled)
                .labelsHidden()
                .toggleStyle(.checkbox)
            Text(label)
                .foregroundStyle(enabled ? .primary : .secondary)
                .frame(width: 140, alignment: .leading)
            content
                .opacity(enabled ? 1.0 : 0.4)
        }
    }
}
