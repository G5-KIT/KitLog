# KitLog

A clean, simple amateur radio logging application for macOS, built with SwiftUI and SwiftData.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Language](https://img.shields.io/badge/language-Swift-orange)
![Framework](https://img.shields.io/badge/framework-SwiftUI-purple)

---

## Features

### Logging
- Quick QSO entry form with auto band detection from frequency
- Live UTC clock with seconds, updating in real time
- Manual date/time override for paper log entry
- Duplicate detection with configurable time window
- Station callsign stored per QSO — ideal for /P operation

### WSJT-X Integration
- Real-time UDP listener on port 2237
- Compatible with WSJT-X, JTDX and JS8Call
- Automatic dupe checking on incoming UDP packets
- WSJT-X online/offline indicator based on heartbeat packets
- Supports both modern ADIF (type 12) and legacy binary (type 5) packet formats

### Log Management
- Searchable, sortable log table with column headers
- Filter by callsign, band, mode, country and date range
- Right-click context menu for single and multi-row operations
- Double-click to edit any QSO
- Batch edit multiple QSOs at once (station callsign, band, mode, RST, name, notes)
- Batch delete with confirmation dialog

### Callsign Lookup
- In-app callsign lookup sheet (no browser required)
- Supports 73QRZ, QRZ.com, HamCall and HamQTH
- Configurable lookup site in Preferences

### ADIF Import & Export
- Import from standard ADIF files (.adi, .adif)
- Import from WSJT-X, JTDX and JS8Call log files
- Automatic dupe checking on import
- Export full log to ADIF 3.1.4 format
- STATION_CALLSIGN field included in exports

### Statistics
- Collapsible statistics panel
- Breakdown by band, mode and country
- Most worked callsigns (top 5)
- Click any stat to filter the log table instantly
- Country derived from callsign prefix (200+ DXCC entities)

### Storage & Sync
- SwiftData database stored in a user-chosen folder
- iCloud Drive compatible — point the database at an iCloud Drive folder for automatic multi-Mac sync
- Works fully offline — syncs when reconnected
- Live iCloud sync status indicator

---

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15 or later (to build from source)

---

## Installation

### Option 1 — Build from Source (Recommended)

1. Clone the repository
2. Open `KitLog.xcodeproj` in Xcode (free from the Mac App Store)
3. Select the KitLog target
4. Set minimum deployment to macOS 14.0
5. Hit ⌘R to build and run

No third-party dependencies — KitLog uses only Apple frameworks.

### Option 2 — Pre-built App (Unsigned)

KitLog is not signed or notarised as this requires an Apple Developer account. Pre-built releases are available on the GitHub Releases page as unsigned .app bundles.

Because KitLog is unsigned, macOS Gatekeeper will block it on first launch. Here's how to open it:

**macOS Sequoia (15) and macOS Tahoe (26):**

1. Download and copy `KitLog.app` to your Applications folder
2. Double-click to open it — you will see a warning that it cannot be verified
3. Click **Done** (do not click Move to Trash)
4. Open **System Settings → Privacy & Security**
5. Scroll down to the **Security** section
6. Click **Open Anyway** next to the KitLog entry
7. Click **Open Anyway** again to confirm
8. Enter your Mac administrator password when prompted
9. KitLog will now open — subsequent launches work normally without any warnings

This only needs to be done once. After the first approved launch, KitLog opens like any other app.

**macOS Sonoma (14) and earlier:**

1. Download and copy `KitLog.app` to your Applications folder
2. Right-click (Control-click) the app and choose **Open**
3. Click **Open** in the warning dialog
4. Subsequent launches work normally

---

## First Launch

When KitLog opens for the first time, you will be asked to choose a folder for your database. This is where all your QSOs will be stored.

**For single Mac use:** choose any convenient folder, for example `~/Documents/KitLog`

**For multi-Mac use:** choose a folder inside your iCloud Drive, for example `iCloud Drive/KitLog` — KitLog will sync automatically across all your Macs signed into the same Apple ID.

---

## WSJT-X Setup

In WSJT-X, go to **File → Settings → Reporting** and configure:

| Setting | Value |
|---|---|
| UDP Server | `localhost` or `127.0.0.1` |
| UDP Server port | `2237` |
| Accept UDP requests | ✓ Checked |

The same settings apply for JTDX and JS8Call.

In KitLog, go to **KitLog → Preferences → WSJT-X Integration** and enable the UDP listener. A green dot confirms it is active and a WSJT-X online indicator appears in the entry form when WSJT-X is running.

---

## iCloud Drive Sync

KitLog does not require an Apple Developer account for iCloud sync. Instead:

1. On first launch, choose a folder inside your iCloud Drive as the database location
2. On each additional Mac, choose the same iCloud Drive folder when prompted
3. KitLog reads and writes to the local copy — iCloud Drive handles sync automatically

**Important:** Do not have KitLog open on two Macs simultaneously and actively logging — SQLite does not support concurrent writes from multiple machines.

---

## ADIF Compatibility

KitLog imports ADIF files from:
- Most standard logging programs (Log4OM, MacLoggerDX, etc.)
- WSJT-X (including MFSK/submode handling for FT8, FT4)
- JTDX
- JS8Call

Exported ADIF files are compatible with QRZ Logbook, LoTW, eQSL, ClubLog and most other online logbooks.

---

## Country Prefix Table

KitLog includes a built-in prefix lookup table covering 200+ DXCC entities. The table uses longest-prefix matching and handles:

- UK regional callsigns (G, GW, GI, GM, GD, GU, GJ) and club station prefixes
- Ukraine vs Russia prefixes (correctly separated)
- Special event prefixes (Polish HF/3Z, Spanish AM/AN/AO, etc.)
- Portable suffix stripping (/P, /MM, /QRP etc.)

The derived country is cached in the database for performance.

---

## Project Structure

```
KitLog/
├── KitLogApp.swift          # App entry point, AppState, notification names
├── AppSettings.swift        # User preferences (callsign, RST, dupe, WSJT-X, lookup)
├── FilterState.swift        # Shared filter state between log and stats panel
├── Model/
│   └── QSOEntry.swift       # SwiftData model
├── Helpers/
│   ├── BandHelper.swift     # Frequency → band lookup, mode list
│   ├── ADIFParser.swift     # ADIF import parser (standard + WSJT-X)
│   ├── PrefixLookup.swift   # Callsign prefix → country (200+ entities)
│   └── WsjtxWatcher.swift   # UDP listener for WSJT-X integration
├── Exporters/
│   └── ADIFExporter.swift   # ADIF export
└── Views/
    ├── ContentView.swift        # Main layout
    ├── QSOEntryForm.swift       # QSO entry form, UTC clock, sync indicator
    ├── QSOLogView.swift         # Log table, filters, import/export
    ├── EditQSOView.swift        # Single QSO edit sheet
    ├── BatchEditView.swift      # Batch edit sheet
    ├── StatsView.swift          # Statistics panel
    ├── CallsignLookupView.swift # In-app callsign lookup
    ├── SetupView.swift          # First-run database folder selection
    ├── PreferencesView.swift    # Preferences window
    └── HelpView.swift           # Built-in help system
```

---

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| ⌘⇧I | Import ADIF |
| ⌘⇧E | Export ADIF |
| ⌘, | Preferences |
| ⌘? | KitLog Help |
| Double-click row | Edit QSO |
| Right-click row | Context menu |
| ⌘-click | Select multiple rows |
| ⇧-click | Select range of rows |

---

## Licence

KitLog is open source. Feel free to use, modify and distribute.

---

## Acknowledgements

Built with SwiftUI and SwiftData on macOS. WSJT-X UDP protocol implementation based on the WSJT-X source documentation. Country prefix data based on ITU allocations with amateur radio community corrections.

73 de G0JPS
