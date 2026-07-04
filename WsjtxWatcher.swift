import Foundation
import SwiftData
import Combine
import Network

// MARK: - WSJT-X Packet Types
private enum WsjtxPacketType: UInt32 {
    case heartbeat  = 0
    case status     = 1
    case decode     = 2
    case clear      = 3
    case reply      = 4
    case qsoLogged  = 5   // Legacy binary format
    case close      = 6
    case replay     = 7
    case haltTx     = 8
    case freeText   = 9
    case wsprDecode = 10
    case location   = 11
    case loggedADIF = 12  // Modern ADIF format
}

// MARK: - Safe Data Reader

private class DataReader {
    let data: Data
    var offset: Int = 0

    init(_ data: Data) {
        self.data = data
    }

    var hasData: Bool { offset < data.count }

    func readUInt32() -> UInt32? {
        guard offset + 4 <= data.count else { return nil }
        let b0 = UInt32(data[offset])
        let b1 = UInt32(data[offset + 1])
        let b2 = UInt32(data[offset + 2])
        let b3 = UInt32(data[offset + 3])
        offset += 4
        return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    }

    func readUInt64() -> UInt64? {
        guard offset + 8 <= data.count else { return nil }
        let b0 = UInt64(data[offset])
        let b1 = UInt64(data[offset + 1])
        let b2 = UInt64(data[offset + 2])
        let b3 = UInt64(data[offset + 3])
        let b4 = UInt64(data[offset + 4])
        let b5 = UInt64(data[offset + 5])
        let b6 = UInt64(data[offset + 6])
        let b7 = UInt64(data[offset + 7])
        offset += 8
        return (b0 << 56) | (b1 << 48) | (b2 << 40) | (b3 << 32) |
               (b4 << 24) | (b5 << 16) | (b6 << 8)  | b7
    }

    func readUInt8() -> UInt8? {
        guard offset + 1 <= data.count else { return nil }
        let b = data[offset]
        offset += 1
        return b
    }

    func readString() -> String? {
        guard let length = readUInt32() else { return nil }
        if length == 0xFFFFFFFF { return "" }
        guard offset + Int(length) <= data.count else { return nil }
        let strData = data[offset..<offset + Int(length)]
        offset += Int(length)
        return String(data: strData, encoding: .utf8) ?? ""
    }

    func readDateTime() -> Date? {
        guard let julianDay    = readUInt32() else { return nil }
        guard let msecMidnight = readUInt32() else { return nil }
        guard let _            = readUInt8()  else { return nil }
        let unixDay = Int(julianDay) - 2440588
        let seconds = Double(unixDay) * 86400.0 + Double(msecMidnight) / 1000.0
        return Date(timeIntervalSince1970: seconds)
    }
}

// MARK: - WSJT-X UDP Listener

class WsjtxWatcher: ObservableObject {
    static let shared = WsjtxWatcher()

    @Published var isListening = false
    @Published var lastLoggedCall: String? = nil
    @Published var wsjtxOnline = false

    private var listener: NWListener?
    private var modelContext: ModelContext?
    private var settings = AppSettings.shared
    private var cancellables = Set<AnyCancellable>()
    private var heartbeatTimer: Timer?

    private let port: NWEndpoint.Port = 2237
    private let magicNumber: UInt32 = 0xADBCCBDA

    private init() {}

    func start(modelContext: ModelContext) {
        self.modelContext = modelContext

        settings.$wsjtxAutoImport
            .sink { [weak self] enabled in
                if enabled {
                    self?.startListening()
                } else {
                    self?.stopListening()
                }
            }
            .store(in: &cancellables)
    }

    func stop() {
        stopListening()
        cancellables.removeAll()
    }

    private func startListening() {
        stopListening()

        do {
            let params = NWParameters.udp
            listener = try NWListener(using: params, on: port)

            listener?.newConnectionHandler = { [weak self] connection in
                connection.start(queue: .global(qos: .background))
                self?.receive(on: connection)
            }

            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isListening = true
                        print("KitLog: WSJT-X UDP listener active on port 2237")
                    case .failed(let error):
                        self?.isListening = false
                        print("KitLog: UDP listener failed: \(error)")
                    case .cancelled:
                        self?.isListening = false
                    default:
                        break
                    }
                }
            }

            listener?.start(queue: .global(qos: .background))

        } catch {
            print("KitLog: could not start UDP listener: \(error)")
        }
    }

    private func stopListening() {
        listener?.cancel()
        listener = nil
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        DispatchQueue.main.async {
            self.isListening = false
            self.wsjtxOnline = false
        }
    }

    private func receive(on connection: NWConnection) {
        connection.receiveMessage { [weak self] data, _, _, error in
            if let data {
                self?.handlePacket(data)
            }
            if error == nil {
                self?.receive(on: connection)
            }
        }
    }

    // MARK: - Packet Parsing

    private func handlePacket(_ data: Data) {
        let reader = DataReader(data)

        guard let magic = reader.readUInt32(),
              magic == magicNumber else { return }

        guard let _ = reader.readUInt32() else { return } // schema
        guard let typeRaw = reader.readUInt32(),
              let packetType = WsjtxPacketType(rawValue: typeRaw) else { return }
        guard let _ = reader.readString() else { return } // client ID

        switch packetType {
        case .heartbeat:
            handleHeartbeat()

        case .qsoLogged:
            handleLegacyQSOLogged(reader: reader)

        case .loggedADIF:
            handleLoggedADIF(reader: reader)

        default:
            break
        }
    }

    // MARK: - Heartbeat

    private func handleHeartbeat() {
        DispatchQueue.main.async {
            self.wsjtxOnline = true
            // Reset online status if no heartbeat for 30 seconds
            self.heartbeatTimer?.invalidate()
            self.heartbeatTimer = Timer.scheduledTimer(
                withTimeInterval: 30.0,
                repeats: false
            ) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.wsjtxOnline = false
                }
            }
        }
    }

    // MARK: - Type 12: Logged ADIF (modern WSJT-X)

    private func handleLoggedADIF(reader: DataReader) {
        guard let adifString = reader.readString(), !adifString.isEmpty else { return }

        print("KitLog: received loggedADIF packet")
        print("KitLog: ADIF content: \(adifString)")

        // Wrap in a minimal ADIF document and parse
        let fullADIF = "<ADIF_VER:5>3.1.4\n<EOH>\n\(adifString)<EOR>"
        let (entries, _) = ADIFParser.parse(fullADIF)

        guard let entry = entries.first else {
            print("KitLog: could not parse ADIF from loggedADIF packet")
            return
        }

        entry.stationCallsign = settings.stationCallsign
        insertQSO(entry)
    }

    // MARK: - Type 5: Legacy binary QSO Logged

    private func handleLegacyQSOLogged(reader: DataReader) {
        guard let dateTimeVal  = reader.readDateTime() else { return }
        guard let callsign     = reader.readString()   else { return }
        guard let _            = reader.readString()   else { return } // DX Grid
        guard let freqHz       = reader.readUInt64()   else { return }
        guard let mode         = reader.readString()   else { return }
        guard let rstSent      = reader.readString()   else { return }
        guard let rstRcvd      = reader.readString()   else { return }
        guard let _            = reader.readString()   else { return } // TX Power
        guard let comments     = reader.readString()   else { return }
        guard let name         = reader.readString()   else { return }

        let frequencyMHz = Double(freqHz) / 1_000_000.0
        let band = BandHelper.band(forFrequency: frequencyMHz)
        let cleanCall = callsign.uppercased().trimmingCharacters(in: .whitespaces)

        let entry = QSOEntry(
            callsign: cleanCall,
            frequency: frequencyMHz,
            band: band,
            mode: mode.uppercased(),
            rstSent: rstSent.isEmpty ? "599" : rstSent,
            rstReceived: rstRcvd.isEmpty ? "599" : rstRcvd,
            dateTime: dateTimeVal,
            operatorName: name,
            notes: comments,
            stationCallsign: settings.stationCallsign
        )

        insertQSO(entry)
    }

    // MARK: - Common insert logic

    private func insertQSO(_ entry: QSOEntry) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let modelContext = self.modelContext else { return }

            let dupeDescriptor = FetchDescriptor<QSOEntry>()
            let existing = (try? modelContext.fetch(dupeDescriptor)) ?? []
            let roundedDate = Int(entry.dateTime.timeIntervalSince1970 / 60)
            let signature = "\(entry.callsign)|\(entry.band)|\(entry.mode)|\(roundedDate)"

            let isDupe = existing.contains { qso in
                let qsoRounded = Int(qso.dateTime.timeIntervalSince1970 / 60)
                let qsoSig = "\(qso.callsign)|\(qso.band)|\(qso.mode)|\(qsoRounded)"
                return qsoSig == signature
            }

            guard !isDupe else {
                print("KitLog: duplicate QSO ignored — \(entry.callsign)")
                return
            }

            modelContext.insert(entry)
            self.lastLoggedCall = entry.callsign
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.lastLoggedCall = nil
            }
            print("KitLog: logged from WSJT-X — \(entry.callsign) on \(entry.band) \(entry.mode)")
        }
    }
}
