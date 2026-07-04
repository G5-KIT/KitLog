import SwiftUI

struct EditQSOView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var qso: QSOEntry

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Contact") {
                    HStack {
                        Text("Callsign")
                        Spacer()
                        TextField("Callsign", text: $qso.callsign)
                            .onChange(of: qso.callsign) { _, v in
                                qso.callsign = v.uppercased()
                            }
                            .multilineTextAlignment(.trailing)
                            .frame(width: 150)
                    }

                    HStack {
                        Text("Frequency (MHz)")
                        Spacer()
                        TextField("0.0", value: $qso.frequency, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Band")
                        Spacer()
                        Text(qso.frequency > 0
                             ? BandHelper.band(forFrequency: qso.frequency)
                             : qso.band)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Mode")
                        Spacer()
                        Picker("", selection: $qso.mode) {
                            ForEach(BandHelper.commonModes, id: \.self) {
                                Text($0)
                            }
                        }
                        .frame(width: 120)
                    }
                }

                Section("Signal Reports") {
                    HStack {
                        Text("RST Sent")
                        Spacer()
                        TextField("59", text: $qso.rstSent)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("RST Received")
                        Spacer()
                        TextField("59", text: $qso.rstReceived)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section("Date / Time (UTC)") {
                    DatePicker(
                        "",
                        selection: $qso.dateTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }

                Section("Additional Info") {
                    HStack {
                        Text("Operator Name")
                        Spacer()
                        TextField("Optional", text: $qso.operatorName)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 150)
                    }

                    HStack {
                        Text("QTH")
                        Spacer()
                        TextField("Optional", text: $qso.qth)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 150)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $qso.notes)
                        .frame(minHeight: 80)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
        }
        .frame(minWidth: 450, minHeight: 500)
        .navigationTitle("Edit — \(qso.callsign)")
    }
}
