import Foundation

struct BandHelper {

    static func band(forFrequency mhz: Double) -> String {
        switch mhz {
        case 1.8..<2.0:        return "160m"
        case 3.5..<4.0:        return "80m"
        case 5.3..<5.41:       return "60m"
        case 7.0..<7.3:        return "40m"
        case 10.1..<10.15:     return "30m"
        case 14.0..<14.35:     return "20m"
        case 18.068..<18.168:  return "17m"
        case 21.0..<21.45:     return "15m"
        case 24.89..<24.99:    return "12m"
        case 28.0..<29.7:      return "10m"
        case 50.0..<54.0:      return "6m"
        case 144.0..<148.0:    return "2m"
        case 420.0..<450.0:    return "70cm"
        default:                return "Other"
        }
    }

    // Given a band name, returns the typical dial frequency for that band
    // Used when importing ADIF records that have band but no frequency
    static func defaultFrequency(forBand band: String) -> Double {
        switch band.lowercased() {
        case "160m": return 1.9
        case "80m":  return 3.7
        case "60m":  return 5.357
        case "40m":  return 7.1
        case "30m":  return 10.12
        case "20m":  return 14.2
        case "17m":  return 18.1
        case "15m":  return 21.2
        case "12m":  return 24.94
        case "10m":  return 28.4
        case "6m":   return 50.15
        case "2m":   return 144.3
        case "70cm": return 432.0
        default:     return 0
        }
    }

    static let commonModes = [
        "SSB", "CW", "AM", "FM",
        "FT8", "FT4", "JS8",
        "PSK31", "PSK63", "RTTY",
        "DMR", "D-STAR", "C4FM"
    ]
}
