import SwiftUI
import SwiftData
import Combine
import Network

// MARK: - Sync Status

enum SyncStatus {
    case synced
    case syncing
    case offline
    case local

    var icon: String {
        switch self {
        case .synced:  return "checkmark.icloud"
        case .syncing: return "arrow.triangle.2.circlepath.icloud"
        case .offline: return "icloud.slash"
        case .local:   return "internaldrive"
        }
    }

    var label: String {
        switch self {
        case .synced:  return "Synced"
        case .syncing: return "Syncing…"
        case .offline: return "Offline"
        case .local:   return "Local"
        }
    }

    var color: Color {
        switch self {
        case .synced:  return .green
        case .syncing: return .blue
        case .offline: return .orange
        case .local:   return .secondary
        }
    }
}

// MARK: - Sync Monitor

class SyncMonitor: ObservableObject {
    @Published var status: SyncStatus = .local
    private var timer: Timer?
    private var networkMonitor: NWPathMonitor?
    private var isOnline = true
    var fileURL: URL?

    func start(fileURL: URL) {
        self.fileURL = fileURL

        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                self?.checkStatus()
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
        self.networkMonitor = monitor

        checkStatus()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkStatus()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        networkMonitor?.cancel()
        networkMonitor = nil
    }

    private func checkStatus() {
        guard let url = fileURL else {
            DispatchQueue.main.async { self.status = .local }
            return
        }

        guard isOnline else {
            DispatchQueue.main.async { self.status = .offline }
            return
        }

        guard let values = try? url.resourceValues(
            forKeys: [
                .ubiquitousItemIsUploadedKey,
                .ubiquitousItemIsUploadingKey,
                .ubiquitousItemIsDownloadingKey,
            ]
        ) else {
            DispatchQueue.main.async { self.status = .local }
            return
        }

        let isUploading   = values.ubiquitousItemIsUploading ?? false
        let isDownloading = values.ubiquitousItemIsDownloading ?? false
        let isUploaded    = values.ubiquitousItemIsUploaded ?? false

        DispatchQueue.main.async {
            if isUploading || isDownloading {
                self.status = .syncing
            } else if isUploaded {
                self.status = .synced
            } else {
                self.status = .offline
            }
        }
    }
}

// MARK: - Clock Timer

class ClockTimer: ObservableObject {
    @Published var now = Date.now
    private var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.now = Date.now
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Entry Form

struct QSOEntryForm: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allQSOs: [QSOEntry]
    @ObservedObject private var settings = AppSettings.shared
    @EnvironmentObject private var appState: AppState

    @StateObject private var syncMonitor = SyncMonitor()
    @StateObject private var clock = ClockTimer()

    @State private var callsign = ""
    @State private var frequencyText = ""
    @State private var mode = "SSB"
    @State private var rstSent = "59"
    @State private var rstReceived = "59"
    @State private var notes = ""
    @State private var showConfirmation = false

    // Date — always UTC date from clock unless manually set
    @State private var manualDate: Date? = nil

    // Time — empty means use live UTC clock
    @State private var manualHour: String = ""
    @State private var manualMinute: String = ""

    // The actual dateTime to log
    var dateTime: Date {
        let baseDate = manualDate ?? clock.now

        // Get UTC date components
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        var components = utcCal.dateComponents([.year, .month, .day], from: baseDate)

        if let h = Int(manualHour), let m = Int(manualMinute),
           manualHour.count == 2, manualMinute.count == 2 {
            components.hour = h
            components.minute = m
            components.second = 0
        } else {
            // Use live UTC clock time
            let clockComponents = utcCal.dateComponents([.hour, .minute, .second], from: clock.now)
            components.hour = clockComponents.hour
            components.minute = clockComponents.minute
            components.second = clockComponents.second
        }

        components.timeZone = TimeZone(identifier: "UTC")
        return utcCal.date(from: components) ?? clock.now
    }

    var isManualTime: Bool {
        manualHour.count == 2 && manualMinute.count == 2
    }

    var utcTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss 'UTC'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: clock.now)
    }

    var utcDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: clock.now)
    }

    var derivedBand: String {
        let mhz = Double(frequencyText) ?? 0
        return mhz > 0 ? BandHelper.band(forFrequency: mhz) : ""
    }

    var dupeWarning: String? {
        guard settings.dupeDetectionEnabled else { return nil }
        let trimmed = callsign.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else { return nil }
        guard !derivedBand.isEmpty else { return nil }

        let windowSeconds = TimeInterval(settings.dupeWindowMinutes * 60)
        let cutoff = Date.now.addingTimeInterval(-windowSeconds)

        let dupe = allQSOs.first {
            $0.callsign == trimmed &&
            $0.band == derivedBand &&
            $0.mode == mode &&
            $0.dateTime > cutoff
        }

        if let dupe {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.timeZone = TimeZone(identifier: "UTC")
            return "⚠️ Possible dupe — \(dupe.callsign) already logged on \(dupe.band) \(dupe.mode) at \(formatter.string(from: dupe.dateTime))z"
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Title row with live UTC clock
            HStack {
                Text("Log a QSO")
                    .font(.headline)
                Spacer()
                Text(utcTimeString)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(isManualTime ? .secondary : .primary)
                if isManualTime || manualDate != nil {
                    Button("Reset to UTC") {
                        manualDate = nil
                        manualHour = ""
                        manualMinute = ""
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
            }

            HStack(spacing: 12) {

                // Callsign
                VStack(alignment: .leading, spacing: 4) {
                    Text("Callsign").font(.caption).foregroundStyle(.secondary)
                    TextField("e.g. G4ABC", text: $callsign)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: callsign) { _, v in
                            callsign = v.uppercased()
                        }
                        .frame(width: 110)
                }

                // Frequency
                VStack(alignment: .leading, spacing: 4) {
                    Text("Freq (MHz)").font(.caption).foregroundStyle(.secondary)
                    TextField("14.225", text: $frequencyText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                }

                // Band (derived)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Band").font(.caption).foregroundStyle(.secondary)
                    Text(derivedBand.isEmpty ? "—" : derivedBand)
                        .frame(width: 55, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                }

                // Mode
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mode").font(.caption).foregroundStyle(.secondary)
                    Picker("", selection: $mode) {
                        ForEach(BandHelper.commonModes, id: \.self) {
                            Text($0)
                        }
                    }
                    .frame(width: 100)
                }

                // RST Sent
                VStack(alignment: .leading, spacing: 4) {
                    Text("RST Sent").font(.caption).foregroundStyle(.secondary)
                    TextField("59", text: $rstSent)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 55)
                }

                // RST Received
                VStack(alignment: .leading, spacing: 4) {
                    Text("RST Rcvd").font(.caption).foregroundStyle(.secondary)
                    TextField("59", text: $rstReceived)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 55)
                }

                // Date (UTC) — date picker only
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date (UTC)").font(.caption).foregroundStyle(.secondary)
                    DatePicker("", selection: Binding(
                        get: { manualDate ?? clock.now },
                        set: { manualDate = $0 }
                    ), displayedComponents: [.date])
                    .labelsHidden()
                }

                // Time (UTC) — manual HH MM fields
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time UTC (HH MM)").font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        TextField("HH", text: $manualHour)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 36)
                            .onChange(of: manualHour) { _, v in
                                manualHour = String(v.filter { $0.isNumber }.prefix(2))
                            }
                        Text(":").foregroundStyle(.secondary)
                        TextField("MM", text: $manualMinute)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 36)
                            .onChange(of: manualMinute) { _, v in
                                manualMinute = String(v.filter { $0.isNumber }.prefix(2))
                            }
                    }
                }

                Spacer()
            }

            HStack(spacing: 12) {
                // Notes
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes").font(.caption).foregroundStyle(.secondary)
                    TextField("Optional…", text: $notes)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)
                }

                // Log button
                Button(action: logQSO) {
                    Label("Log QSO", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(callsign.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.top, 18)

                // Confirmation flash
                if showConfirmation {
                    Label("Logged!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .padding(.top, 18)
                        .transition(.opacity)
                }

                // WSJT-X flash
                if let call = WsjtxWatcher.shared.lastLoggedCall {
                    Label("WSJT-X: \(call)", systemImage: "antenna.radiowaves.left.and.right")
                        .foregroundStyle(.blue)
                        .padding(.top, 18)
                        .transition(.opacity)
                }

                // Sync indicator
                SyncIndicatorView(status: syncMonitor.status)
                    .padding(.top, 18)

                // WSJT-X online indicator
                if AppSettings.shared.wsjtxAutoImport {
                    WsjtxStatusView(online: WsjtxWatcher.shared.wsjtxOnline)
                        .padding(.top, 18)
                }
            }

            // Dupe warning
            if let warning = dupeWarning {
                HStack(spacing: 6) {
                    Text(warning)
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.orange.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: 6))
                .transition(.opacity)
            }
        }
        .padding()
        .animation(.easeInOut(duration: 0.2), value: dupeWarning)
        .animation(.easeInOut(duration: 0.2), value: WsjtxWatcher.shared.lastLoggedCall)
        .onAppear {
            rstSent = settings.defaultRSTSent
            rstReceived = settings.defaultRSTReceived
            if let url = appState.currentStoreURL() {
                syncMonitor.start(fileURL: url)
            }
            clock.start()
        }
        .onDisappear {
            syncMonitor.stop()
            clock.stop()
        }
    }

    private func logQSO() {
        let freq = Double(frequencyText) ?? 0
        let entry = QSOEntry(
            callsign: callsign.trimmingCharacters(in: .whitespaces),
            frequency: freq,
            band: derivedBand,
            mode: mode,
            rstSent: rstSent.isEmpty ? settings.defaultRSTSent : rstSent,
            rstReceived: rstReceived.isEmpty ? settings.defaultRSTReceived : rstReceived,
            dateTime: dateTime,
            notes: notes,
            stationCallsign: settings.stationCallsign
        )
        modelContext.insert(entry)
        resetForm()

        withAnimation {
            showConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showConfirmation = false }
        }
    }

    private func resetForm() {
        callsign = ""
        frequencyText = ""
        mode = "SSB"
        rstSent = settings.defaultRSTSent
        rstReceived = settings.defaultRSTReceived
        notes = ""
        manualDate = nil
        manualHour = ""
        manualMinute = ""
    }
}

// MARK: - Sync Indicator View

struct SyncIndicatorView: View {
    let status: SyncStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .foregroundStyle(status.color)
            Text(status.label)
                .font(.caption)
                .foregroundStyle(status.color)
        }
        .help("iCloud Drive: \(status.label)")
    }
}
// MARK: - WSJT-X Status View

struct WsjtxStatusView: View {
    let online: Bool

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(online ? Color.green : Color.secondary)
                .frame(width: 8, height: 8)
            Text(online ? "WSJT-X" : "WSJT-X offline")
                .font(.caption)
                .foregroundStyle(online ? .primary : .secondary)
        }
        .help(online ? "WSJT-X is connected and sending data" : "No WSJT-X heartbeat received")
    }
}
