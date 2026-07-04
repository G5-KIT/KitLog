import Foundation
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // Your station callsign
    @Published var stationCallsign: String {
        didSet { UserDefaults.standard.set(stationCallsign, forKey: "stationCallsign") }
    }

    // Default RST values
    @Published var defaultRSTSent: String {
        didSet { UserDefaults.standard.set(defaultRSTSent, forKey: "defaultRSTSent") }
    }
    @Published var defaultRSTReceived: String {
        didSet { UserDefaults.standard.set(defaultRSTReceived, forKey: "defaultRSTReceived") }
    }

    // Dupe detection
    @Published var dupeDetectionEnabled: Bool {
        didSet { UserDefaults.standard.set(dupeDetectionEnabled, forKey: "dupeDetectionEnabled") }
    }

    // Dupe window in minutes
    @Published var dupeWindowMinutes: Int {
        didSet { UserDefaults.standard.set(dupeWindowMinutes, forKey: "dupeWindowMinutes") }
    }

    // WSJT-X log file path
    @Published var wsjtxLogPath: String {
        didSet { UserDefaults.standard.set(wsjtxLogPath, forKey: "wsjtxLogPath") }
    }

    // WSJT-X auto import enabled
    @Published var wsjtxAutoImport: Bool {
        didSet { UserDefaults.standard.set(wsjtxAutoImport, forKey: "wsjtxAutoImport") }
    }
    
    // Callsign lookup site
    @Published var lookupSite: String {
        didSet { UserDefaults.standard.set(lookupSite, forKey: "lookupSite") }
    }

    private init() {
        self.stationCallsign    = UserDefaults.standard.string(forKey: "stationCallsign") ?? ""
        self.defaultRSTSent     = UserDefaults.standard.string(forKey: "defaultRSTSent") ?? "59"
        self.defaultRSTReceived = UserDefaults.standard.string(forKey: "defaultRSTReceived") ?? "59"
        self.dupeDetectionEnabled = UserDefaults.standard.bool(forKey: "dupeDetectionEnabled")
        self.dupeWindowMinutes  = UserDefaults.standard.integer(forKey: "dupeWindowMinutes") == 0
            ? 30
            : UserDefaults.standard.integer(forKey: "dupeWindowMinutes")
        self.wsjtxLogPath       = UserDefaults.standard.string(forKey: "wsjtxLogPath") ?? ""
        self.wsjtxAutoImport    = UserDefaults.standard.bool(forKey: "wsjtxAutoImport")
        self.lookupSite = UserDefaults.standard.string(forKey: "lookupSite") ?? "73QRZ"
    }
}
