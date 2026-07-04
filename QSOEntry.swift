import Foundation
import SwiftData

@Model
class QSOEntry {
    var id: UUID
    var callsign: String
    var frequency: Double
    var band: String
    var mode: String
    var subMode: String
    var rstSent: String
    var rstReceived: String
    var dateTime: Date
    var operatorName: String
    var qth: String
    var notes: String
    var stationCallsign: String
    var country: String

    init(
        callsign: String,
        frequency: Double = 0,
        band: String = "",
        mode: String = "SSB",
        subMode: String = "",
        rstSent: String = "59",
        rstReceived: String = "59",
        dateTime: Date = .now,
        operatorName: String = "",
        qth: String = "",
        notes: String = "",
        stationCallsign: String = "",
        country: String = ""
    ) {
        self.id = UUID()
        self.callsign = callsign
        self.frequency = frequency
        self.band = band
        self.mode = mode
        self.subMode = subMode
        self.rstSent = rstSent
        self.rstReceived = rstReceived
        self.dateTime = dateTime
        self.operatorName = operatorName
        self.qth = qth
        self.notes = notes
        self.stationCallsign = stationCallsign
        self.country = country.isEmpty ? PrefixLookup.country(for: callsign) : country
    }
}
