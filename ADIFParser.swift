import Foundation

struct ADIFParser {

    struct ParseResult {
        var imported: Int = 0
        var skipped: Int = 0
        var errors: [String] = []
    }

    // Parse an ADIF string and return an array of QSOEntry objects
    static func parse(_ adif: String) -> (entries: [QSOEntry], result: ParseResult) {
        var entries: [QSOEntry] = []
        var result = ParseResult()

        // Split on <EOR> (case insensitive)
        let records = adif
            .replacingOccurrences(of: "<eor>", with: "<EOR>", options: .caseInsensitive)
            .components(separatedBy: "<EOR>")

        for record in records {
            let trimmed = record.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            // Skip the header block (contains <EOH> but no <CALL:> field)
            if trimmed.range(of: "EOH", options: .caseInsensitive) != nil &&
               trimmed.range(of: "CALL:", options: .caseInsensitive) == nil { continue }

            let fields = parseFields(from: trimmed)

            // Callsign is mandatory
            guard let callsign = fields["CALL"], !callsign.isEmpty else {
                result.skipped += 1
                continue
            }

            // Build date/time from QSO_DATE and TIME_ON
            let dateTime = parseDateTime(
                date: fields["QSO_DATE"] ?? "",
                time: fields["TIME_ON"] ?? ""
            )

            // Frequency — prefer FREQ, fall back to band default
            var frequency: Double = 0
            if let freqStr = fields["FREQ"], let freqVal = Double(freqStr) {
                frequency = freqVal
            }

            // Band — prefer BAND field, derive from frequency if missing
            var band = fields["BAND"] ?? ""
            if band.isEmpty && frequency > 0 {
                band = BandHelper.band(forFrequency: frequency)
            }
            if frequency == 0 && !band.isEmpty {
                frequency = BandHelper.defaultFrequency(forBand: band)
            }

            // Mode — handle WSJT-X MFSK/submode convention
            var mode = fields["MODE"] ?? "SSB"
            var subMode = fields["SUBMODE"] ?? ""

            // WSJT-X logs FT8 and FT4 as MODE=FT8/FT4 in newer versions
            // but older versions use MODE=MFSK with SUBMODE=FT8 etc
            if mode.uppercased() == "MFSK" && !subMode.isEmpty {
                mode = subMode
                subMode = ""
            }

            // JS8Call logs as JS8
            if mode.uppercased() == "JS8CALL" {
                mode = "JS8"
            }

            if mode.isEmpty { mode = "SSB" }

            let entry = QSOEntry(
                callsign: callsign.uppercased().trimmingCharacters(in: .whitespaces),
                frequency: frequency,
                band: band,
                mode: mode.uppercased(),
                subMode: subMode.uppercased(),
                rstSent: fields["RST_SENT"] ?? "59",
                rstReceived: fields["RST_RCVD"] ?? "59",
                dateTime: dateTime ?? .now,
                operatorName: fields["NAME"] ?? "",
                qth: fields["QTH"] ?? "",
                notes: fields["COMMENT"] ?? fields["NOTES"] ?? ""
            )

            entries.append(entry)
            result.imported += 1
        }

        return (entries, result)
    }

    // MARK: - Private helpers

    // Extract all <TAG:length>value fields from a record string
    private static func parseFields(from record: String) -> [String: String] {
        var fields: [String: String] = [:]

        // Match <TAG:length>value or <TAG:length:type>value
        let pattern = try! NSRegularExpression(
            pattern: "<([A-Za-z_]+):(\\d+)(?::[A-Za-z])?>(.*?)(?=<[A-Za-z_]+:\\d|$)",
            options: [.dotMatchesLineSeparators]
        )
        let matches = pattern.matches(in: record, range: NSRange(record.startIndex..., in: record))

        for match in matches {
            guard match.numberOfRanges >= 4 else { continue }
            guard let tagRange = Range(match.range(at: 1), in: record),
                  let lenRange = Range(match.range(at: 2), in: record),
                  let valRange = Range(match.range(at: 3), in: record) else { continue }

            let tag = String(record[tagRange]).uppercased()
            let length = Int(record[lenRange]) ?? 0
            let value = String(String(record[valRange]).prefix(length))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            fields[tag] = value
        }


        return fields
    }

    // Parse ADIF date (YYYYMMDD) and time (HHMM or HHMMSS) into a Date
    private static func parseDateTime(date: String, time: String) -> Date? {
        let cleanDate = date.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTime = time.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanDate.count == 8 else { return nil }

        let timeStr = cleanTime.isEmpty ? "0000" : String(cleanTime.prefix(4))
        let combined = "\(cleanDate)\(timeStr)"

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmm"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: combined)
    }
}
