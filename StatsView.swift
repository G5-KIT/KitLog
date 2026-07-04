import SwiftUI
import SwiftData

struct StatsView: View {
    let qsos: [QSOEntry]           // full list for totals
    let filteredQSOs: [QSOEntry]   // filtered list for stats
    @EnvironmentObject private var filterState: FilterState
    
    @State private var isExpanded = false

    var totalQSOs: Int { qsos.count }

    var byBand: [(String, Int)] {
        let grouped = Dictionary(grouping: qsos, by: \.band)
        return grouped
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }

    var byMode: [(String, Int)] {
        let grouped = Dictionary(grouping: qsos, by: \.mode)
        return grouped
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }

    var mostWorked: [(String, Int)] {
        let grouped = Dictionary(grouping: filteredQSOs, by: \.callsign)
        return grouped
            .map { ($0.key, $0.value.count) }
            .filter { $0.1 > 1 }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0 }
    }
    
    var byCountry: [(String, Int)] {
        let grouped = Dictionary(grouping: qsos) {
            $0.country
        }
        return grouped
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }

    var firstQSO: Date? { qsos.map(\.dateTime).min() }
    var lastQSO: Date? { qsos.map(\.dateTime).max() }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            // Header / toggle bar
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                        Text("Statistics")
                            .font(.headline)
                        Text("— \(totalQSOs) QSOs total")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                if filterState.isActive {
                    Button("Clear Stats Filter") {
                        filterState.reset()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.orange)
                    .font(.caption)
                }

                if let first = firstQSO, let last = lastQSO {
                    Text("First: \(dateFormatter.string(from: first))  Last: \(dateFormatter.string(from: last))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Collapsible content
            if isExpanded {
                ScrollView {
                    HStack(alignment: .top, spacing: 24) {

                        // By Band
                        VStack(alignment: .leading, spacing: 6) {
                            Text("By Band")
                                .font(.subheadline)
                                .bold()
                            ForEach(byBand, id: \.0) { band, count in
                                HStack {
                                    Text(band.isEmpty ? "Unknown" : band)
                                        .frame(width: 60, alignment: .leading)
                                    ProgressView(
                                        value: Double(count),
                                        total: Double(totalQSOs)
                                    )
                                    .frame(width: 80)
                                    Text("\(count)")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 35, alignment: .trailing)
                                }
                                .font(.callout)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 4)
                                .background(
                                    filterState.band == band
                                        ? Color.accentColor.opacity(0.15)
                                        : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 4)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if filterState.band == band {
                                        filterState.band = "All"
                                    } else {
                                        filterState.band = band
                                    }
                                }
                                .help("Click to filter by \(band)")
                            }
                        }
                        .frame(minWidth: 200, alignment: .leading)

                        Divider()

                        // By Mode
                        VStack(alignment: .leading, spacing: 6) {
                            Text("By Mode")
                                .font(.subheadline)
                                .bold()
                            ForEach(byMode, id: \.0) { mode, count in
                                HStack {
                                    Text(mode.isEmpty ? "Unknown" : mode)
                                        .frame(width: 60, alignment: .leading)
                                    ProgressView(
                                        value: Double(count),
                                        total: Double(totalQSOs)
                                    )
                                    .frame(width: 80)
                                    Text("\(count)")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 35, alignment: .trailing)
                                }
                                .font(.callout)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 4)
                                .background(
                                    filterState.mode == mode
                                        ? Color.accentColor.opacity(0.15)
                                        : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 4)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if filterState.mode == mode {
                                        filterState.mode = "All"
                                    } else {
                                        filterState.mode = mode
                                    }
                                }
                                .help("Click to filter by \(mode)")
                            }
                        }
                        .frame(minWidth: 200, alignment: .leading)

                        Divider()

                        // Most Worked
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Most Worked")
                                .font(.subheadline)
                                .bold()
                            if mostWorked.isEmpty {
                                Text("No repeated callsigns yet")
                                    .foregroundStyle(.secondary)
                                    .font(.callout)
                            } else {
                                ForEach(mostWorked, id: \.0) { call, count in
                                    HStack {
                                        Text(call)
                                            .bold()
                                            .frame(width: 90, alignment: .leading)
                                        Text("\(count) QSOs")
                                            .foregroundStyle(.secondary)
                                    }
                                    .font(.callout)
                                }
                            }
                        }
                        .frame(minWidth: 160, alignment: .leading)

                        Divider()

                        // By Country
                        VStack(alignment: .leading, spacing: 6) {
                            Text("By Country (\(byCountry.count))")
                                .font(.subheadline)
                                .bold()
                            ForEach(byCountry, id: \.0) { country, count in
                                HStack {
                                    Text(country)
                                        .frame(width: 140, alignment: .leading)
                                    ProgressView(
                                        value: Double(count),
                                        total: Double(totalQSOs)
                                    )
                                    .frame(width: 80)
                                    Text("\(count)")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 35, alignment: .trailing)
                                }
                                .font(.callout)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 4)
                                .background(
                                    filterState.country == country
                                        ? Color.accentColor.opacity(0.15)
                                        : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 4)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if filterState.country == country {
                                        filterState.country = "All"
                                    } else {
                                        filterState.country = country
                                    }
                                }
                                .help("Click to filter by \(country)")
                            }
                        }
                        .frame(minWidth: 280, alignment: .leading)

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .frame(maxHeight: 200)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .background(.background)
    }
}
