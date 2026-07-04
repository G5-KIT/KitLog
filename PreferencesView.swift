import SwiftUI
import AppKit

struct PreferencesView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var watcher = WsjtxWatcher.shared

    var body: some View {
        Form {
            Section("Station") {
                HStack {
                    Text("Your Callsign")
                    Spacer()
                    TextField("e.g. G0ABC", text: $settings.stationCallsign)
                        .onChange(of: settings.stationCallsign) { _, v in
                            settings.stationCallsign = v.uppercased()
                        }
                        .multilineTextAlignment(.trailing)
                        .frame(width: 150)
                }
            }

            Section("Defaults") {
                HStack {
                    Text("Default RST Sent")
                    Spacer()
                    TextField("59", text: $settings.defaultRSTSent)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                HStack {
                    Text("Default RST Received")
                    Spacer()
                    TextField("59", text: $settings.defaultRSTReceived)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }

            Section("Duplicate Detection") {
                Toggle("Warn on duplicate QSO", isOn: $settings.dupeDetectionEnabled)

                HStack {
                    Text("Time window")
                    Spacer()
                    Stepper(
                        "\(settings.dupeWindowMinutes) minutes",
                        value: $settings.dupeWindowMinutes,
                        in: 1...1440,
                        step: 5
                    )
                    .disabled(!settings.dupeDetectionEnabled)
                }
            }
            
            Section("Callsign Lookup") {
                HStack {
                    Text("Lookup Site")
                    Spacer()
                    Picker("", selection: $settings.lookupSite) {
                        Text("73QRZ").tag("73QRZ")
                        Text("QRZ.com").tag("QRZ.com")
                        Text("HamCall").tag("HamCall")
                        Text("HamQTH").tag("HamQTH")
                    }
                    .frame(width: 150)
                }
            }

            Section("WSJT-X Integration") {
                Toggle("Listen for WSJT-X QSOs (UDP port 2237)", isOn: $settings.wsjtxAutoImport)

                HStack {
                    Text("Status")
                    Spacer()
                    if settings.wsjtxAutoImport {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(watcher.isListening ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text(watcher.isListening ? "Listening" : "Starting…")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Disabled")
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Make sure WSJT-X is set to send UDP packets to port 2237 under File → Settings → Reporting.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .padding()
        .navigationTitle("Preferences")
    }
}
