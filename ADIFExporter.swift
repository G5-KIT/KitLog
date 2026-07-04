import Foundation

struct ADIFExporter {

    static func export(_ qsos: [QSOEntry]) -> String {
        var output = ""

        // Header
        output += "<ADIF_VER:5>3.1.4\n"
        output += "<PROGRAMID:6>KitLog\n"
        output += "<EOH>\n\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HHmm"
        timeFormatter.timeZone = TimeZone(identifier: "UTC")

        for q in qsos {
            output += field("CALL", q.callsign)
            if !q.stationCallsign.isEmpty {
                output += field("STATION_CALLSIGN", q.stationCallsign)
            }
            output += field("QSO_DATE", dateFormatter.string(from: q.dateTime))
            output += field("TIME_ON", timeFormatter.string(from: q.dateTime))
            output += field("BAND", q.band)
            output += field("MODE", q.mode)
            if !q.subMode.isEmpty {
                output += field("SUBMODE", q.subMode)
            }
            if q.frequency > 0 {
                output += field("FREQ", String(format: "%.4f", q.frequency))
            }
            output += field("RST_SENT", q.rstSent)
            output += field("RST_RCVD", q.rstReceived)
            if !q.operatorName.isEmpty {
                output += field("NAME", q.operatorName)
            }
            if !q.qth.isEmpty {
                output += field("QTH", q.qth)
            }
            if !q.notes.isEmpty {
                output += field("COMMENT", q.notes)
            }
            output += "<EOR>\n"
        }

        return output
    }

    private static func field(_ tag: String, _ value: String) -> String {
        guard !value.isEmpty else { return "" }
        return "<\(tag):\(value.count)>\(value) "
    }
}
