import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct QSOLogView: View {
    @Query(sort: \QSOEntry.dateTime, order: .reverse) private var qsos: [QSOEntry]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var filterState: FilterState

    @State private var editingQSO: QSOEntry?
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var exportContent = ""
    @State private var importResult: String?
    @State private var showingImportResult = false
    @State private var sortOrder = [KeyPathComparator(\QSOEntry.dateTime, order: .reverse)]
    @State private var selectedQSOs = Set<QSOEntry.ID>()
    @State private var showingBatchEdit = false
    @State private var showingBatchDelete = false
    @State private var pendingDeleteIDs = Set<QSOEntry.ID>()
    @State private var lookupCallsign: String? = nil

    // Filters
    @State private var filterCallsign = ""
    @State private var filterBand = "All"
    @State private var filterMode = "All"
    @State private var filterCountry = "All"
    @State private var filterDateFrom: Date? = nil
    @State private var filterDateTo: Date? = nil
    @State private var showDateFrom = false
    @State private var showDateTo = false

    var availableBands: [String] {
        let bands = Set(qsos.map { $0.band }).filter { !$0.isEmpty }
        return ["All"] + bands.sorted()
    }

    var availableModes: [String] {
        let modes = Set(qsos.map { $0.mode }).filter { !$0.isEmpty }
        return ["All"] + modes.sorted()
    }

    var availableCountries: [String] {
        let countries = Set(qsos.map { $0.country }).filter { !$0.isEmpty }
        return ["All"] + countries.sorted()
    }

    var isFiltered: Bool {
        !filterCallsign.isEmpty ||
        filterBand != "All" ||
        filterMode != "All" ||
        filterCountry != "All" ||
        filterDateFrom != nil ||
        filterDateTo != nil ||
        filterState.isActive
    }

    var filtered: [QSOEntry] {
        var results = qsos

        if !filterCallsign.isEmpty {
            let q = filterCallsign.uppercased()
            results = results.filter { $0.callsign.uppercased().contains(q) }
        }

        let activeBand = filterBand != "All" ? filterBand : filterState.band
        if activeBand != "All" {
            results = results.filter { $0.band == activeBand }
        }

        let activeMode = filterMode != "All" ? filterMode : filterState.mode
        if activeMode != "All" {
            results = results.filter { $0.mode == activeMode }
        }

        let activeCountry = filterCountry != "All" ? filterCountry : filterState.country
        if activeCountry != "All" {
            results = results.filter { $0.country == activeCountry }
        }

        if let from = filterDateFrom {
            results = results.filter { $0.dateTime >= from }
        }

        if let to = filterDateTo {
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: to) ?? to
            results = results.filter { $0.dateTime < endOfDay }
        }

        return results.sorted(using: sortOrder)
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yy HH:mm"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yy"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {

            // Toolbar row
            HStack {
                if isFiltered {
                    Text("QSO Log")
                        .font(.headline)
                    Text("(\(filtered.count) of \(qsos.count) contacts)")
                        .foregroundStyle(.secondary)
                } else {
                    Text("QSO Log")
                        .font(.headline)
                    Text("(\(qsos.count) contacts)")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if selectedQSOs.count > 1 {
                    Button("Batch Edit (\(selectedQSOs.count))") {
                        showingBatchEdit = true
                    }
                    .buttonStyle(.bordered)
                }

                if isFiltered {
                    Button("Reset Filters") {
                        resetFilters()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.orange)
                }
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 6)

            // Filter bar
            HStack(spacing: 10) {

                HStack(spacing: 4) {
                    Text("Call:").font(.caption).foregroundStyle(.secondary)
                    TextField("Search…", text: $filterCallsign)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                }

                HStack(spacing: 4) {
                    Text("Band:").font(.caption).foregroundStyle(.secondary)
                    Picker("", selection: $filterBand) {
                        ForEach(availableBands, id: \.self) { Text($0) }
                    }
                    .frame(width: 80)
                }

                HStack(spacing: 4) {
                    Text("Mode:").font(.caption).foregroundStyle(.secondary)
                    Picker("", selection: $filterMode) {
                        ForEach(availableModes, id: \.self) { Text($0) }
                    }
                    .frame(width: 80)
                }

                HStack(spacing: 4) {
                    Text("Country:").font(.caption).foregroundStyle(.secondary)
                    Picker("", selection: $filterCountry) {
                        ForEach(availableCountries, id: \.self) { Text($0) }
                    }
                    .frame(width: 120)
                }

                HStack(spacing: 4) {
                    Text("From:").font(.caption).foregroundStyle(.secondary)
                    if let from = filterDateFrom {
                        HStack(spacing: 2) {
                            Text(shortDateFormatter.string(from: from))
                                .font(.callout)
                            Button {
                                filterDateFrom = nil
                                showDateFrom = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                    } else {
                        Button("Any") { showDateFrom.toggle() }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.secondary)
                    }
                }
                .popover(isPresented: $showDateFrom) {
                    DatePicker("From", selection: Binding(
                        get: { filterDateFrom ?? Date.now },
                        set: { filterDateFrom = $0; showDateFrom = false }
                    ), displayedComponents: [.date])
                    .labelsHidden()
                    .padding()
                }

                HStack(spacing: 4) {
                    Text("To:").font(.caption).foregroundStyle(.secondary)
                    if let to = filterDateTo {
                        HStack(spacing: 2) {
                            Text(shortDateFormatter.string(from: to))
                                .font(.callout)
                            Button {
                                filterDateTo = nil
                                showDateTo = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                    } else {
                        Button("Any") { showDateTo.toggle() }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.secondary)
                    }
                }
                .popover(isPresented: $showDateTo) {
                    DatePicker("To", selection: Binding(
                        get: { filterDateTo ?? Date.now },
                        set: { filterDateTo = $0; showDateTo = false }
                    ), displayedComponents: [.date])
                    .labelsHidden()
                    .padding()
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 6)

            Divider()

            // Log table
            Table(filtered, selection: $selectedQSOs, sortOrder: $sortOrder) {
                TableColumn("Callsign", value: \QSOEntry.callsign) { q in
                    Text(q.callsign)
                        .bold()
                        .foregroundStyle(.primary)
                }
                .width(min: 80, ideal: 100)

                TableColumn("Station", value: \QSOEntry.stationCallsign) { q in
                    Text(q.stationCallsign)
                        .foregroundStyle(.secondary)
                }
                .width(min: 80, ideal: 100)

                TableColumn("Date / Time (UTC)", value: \QSOEntry.dateTime) { q in
                    Text(dateFormatter.string(from: q.dateTime))
                        .font(.system(.body, design: .monospaced))
                }
                .width(min: 120, ideal: 140)

                TableColumn("Freq (MHz)", value: \QSOEntry.frequency) { q in
                    Text(q.frequency > 0 ? String(format: "%.4f", q.frequency) : "—")
                }
                .width(min: 80, ideal: 90)

                TableColumn("Band", value: \QSOEntry.band) { q in
                    Text(q.band)
                }
                .width(min: 50, ideal: 60)

                TableColumn("Mode", value: \QSOEntry.mode) { q in
                    Text(q.subMode.isEmpty ? q.mode : "\(q.mode)/\(q.subMode)")
                }
                .width(min: 60, ideal: 80)

                TableColumn("RST S/R", value: \QSOEntry.rstSent) { q in
                    Text("\(q.rstSent) / \(q.rstReceived)")
                }
                .width(min: 70, ideal: 80)

                TableColumn("Country", value: \QSOEntry.country) { q in
                    Text(q.country)
                        .foregroundStyle(.secondary)
                }
                .width(min: 100, ideal: 120)

                TableColumn("Name", value: \QSOEntry.operatorName) { q in
                    Text(q.operatorName)
                        .foregroundStyle(.secondary)
                }
                .width(min: 80, ideal: 100)

                TableColumn("Notes", value: \QSOEntry.notes) { q in
                    Text(q.notes)
                        .foregroundStyle(.secondary)
                }
                .width(min: 100, ideal: 150)
            }
            .contextMenu(forSelectionType: QSOEntry.ID.self) { items in
                if items.count == 1, let id = items.first,
                   let qso = filtered.first(where: { $0.id == id }) {
                    Button("Look Up \(qso.callsign)") {
                        lookupCallsign = qso.callsign
                    }
                    Divider()
                    Button("Edit QSO") { editingQSO = qso }
                    Divider()
                    Button("Delete QSO", role: .destructive) {
                        pendingDeleteIDs = items
                        showingBatchDelete = true
                    }
                } else if items.count > 1 {
                    Button("Batch Edit \(items.count) QSOs") {
                        selectedQSOs = items
                        showingBatchEdit = true
                    }
                    Divider()
                    Button("Delete \(items.count) QSOs", role: .destructive) {
                        pendingDeleteIDs = items
                        showingBatchDelete = true
                    }
                }
            } primaryAction: { items in
                if items.count == 1, let id = items.first,
                   let qso = filtered.first(where: { $0.id == id }) {
                    editingQSO = qso
                }
            }

            // Stats panel — now inside QSOLogView so it has access to filtered
            StatsView(qsos: qsos, filteredQSOs: filtered)
        }

        .sheet(item: $editingQSO) { qso in
            EditQSOView(qso: qso)
        }
        
        .sheet(item: $lookupCallsign) { callsign in
            CallsignLookupView(callsign: callsign)
        }
        
        .sheet(isPresented: $showingBatchEdit) {
            let selectedEntries = filtered.filter { selectedQSOs.contains($0.id) }
            BatchEditView(qsos: selectedEntries)
        }

        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.plainText,
                                   UTType(filenameExtension: "adi") ?? .plainText,
                                   UTType(filenameExtension: "adif") ?? .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }

        .fileExporter(
            isPresented: $showingExporter,
            document: ADIFDocument(content: exportContent),
            contentType: .plainText,
            defaultFilename: "kitlog_export.adi"
        ) { _ in }

        .alert("Import Complete", isPresented: $showingImportResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importResult ?? "")
        }

        .onReceive(NotificationCenter.default.publisher(for: .importADIF)) { _ in
            showingImporter = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportADIF)) { _ in
            exportContent = ADIFExporter.export(qsos)
            showingExporter = true
        }
        .confirmationDialog(
            "Delete \(pendingDeleteIDs.count) QSOs?",
            isPresented: $showingBatchDelete,
            titleVisibility: .visible
        ) {
            Button("Delete \(pendingDeleteIDs.count) QSOs", role: .destructive) {
                for id in pendingDeleteIDs {
                    if let qso = filtered.first(where: { $0.id == id }) {
                        modelContext.delete(qso)
                    }
                }
                pendingDeleteIDs.removeAll()
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteIDs.removeAll()
            }
        } message: {
            Text("This will permanently delete \(pendingDeleteIDs.count) QSOs. This cannot be undone.")
        }
    }

    private func resetFilters() {
        filterCallsign = ""
        filterBand = "All"
        filterMode = "All"
        filterCountry = "All"
        filterDateFrom = nil
        filterDateTo = nil
        showDateFrom = false
        showDateTo = false
        filterState.reset()
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importResult = "Could not open file: \(error.localizedDescription)"
            showingImportResult = true

        case .success(let urls):
            guard let url = urls.first else { return }

            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing { url.stopAccessingSecurityScopedResource() }
            }

            do {
                let adifString = try String(contentsOf: url, encoding: .utf8)
                let (entries, parseResult) = ADIFParser.parse(adifString)

                let existingSignatures = Set(qsos.map { qso -> String in
                    let roundedDate = Int(qso.dateTime.timeIntervalSince1970 / 60)
                    return "\(qso.callsign)|\(qso.band)|\(qso.mode)|\(roundedDate)"
                })

                var dupeCount = 0
                var insertedCount = 0

                for entry in entries {
                    let roundedDate = Int(entry.dateTime.timeIntervalSince1970 / 60)
                    let signature = "\(entry.callsign)|\(entry.band)|\(entry.mode)|\(roundedDate)"

                    if existingSignatures.contains(signature) {
                        dupeCount += 1
                    } else {
                        modelContext.insert(entry)
                        insertedCount += 1
                    }
                }

                var resultLines = ["Imported \(insertedCount) QSOs successfully."]
                if dupeCount > 0 {
                    resultLines.append("Skipped \(dupeCount) duplicate(s) already in log.")
                }
                if parseResult.skipped > 0 {
                    resultLines.append("Skipped \(parseResult.skipped) record(s) with no callsign.")
                }
                importResult = resultLines.joined(separator: "\n")
                showingImportResult = true

            } catch {
                importResult = "Could not read file: \(error.localizedDescription)"
                showingImportResult = true
            }
        }
    }
    
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - ADIF file document for export

struct ADIFDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var content: String

    init(content: String) {
        self.content = content
    }

    init(configuration: ReadConfiguration) throws {
        content = String(
            data: configuration.file.regularFileContents ?? Data(),
            encoding: .utf8
        ) ?? ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: content.data(using: .utf8)!)
    }
}
