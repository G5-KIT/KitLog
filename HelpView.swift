import SwiftUI

// MARK: - Help Section Model

struct HelpSection: Identifiable {
    let id: String
    let title: String
    let icon: String
    let content: [HelpItem]
}

struct HelpItem: Identifiable {
    let id = UUID()
    let heading: String
    let body: String
}

// MARK: - Help Content

let helpSections: [HelpSection] = [
    HelpSection(
        id: "getting-started",
        title: "Getting Started",
        icon: "star",
        content: [
            HelpItem(
                heading: "First Launch",
                body: "When KitLog opens for the first time, you'll be asked to choose a folder for your database. This is where all your QSOs will be stored.\n\nFor multi-Mac use, choose a folder inside your iCloud Drive — KitLog will sync automatically across all your Macs signed into the same Apple ID."
            ),
            HelpItem(
                heading: "Changing Database Location",
                body: "You can change the database folder at any time via File → Database Location. You'll be asked whether to move your existing database to the new location or leave it where it is and start fresh."
            ),
            HelpItem(
                heading: "iCloud Drive Sync",
                body: "KitLog stores its database as a standard file in your chosen folder. If that folder is inside iCloud Drive, it syncs automatically — no configuration needed.\n\nThe sync indicator in the entry form shows the current sync status: green means synced, blue means syncing, orange means offline.\n\nWhen offline, KitLog works normally and syncs when you reconnect."
            ),
        ]
    ),

    HelpSection(
        id: "logging",
        title: "Logging a QSO",
        icon: "antenna.radiowaves.left.and.right",
        content: [
            HelpItem(
                heading: "Entry Form",
                body: "Fill in the Callsign, Frequency, Mode, RST Sent and RST Received fields, then click Log QSO.\n\nThe Band field is derived automatically from the frequency you enter — you don't need to fill it in manually."
            ),
            HelpItem(
                heading: "Date and Time",
                body: "The date defaults to today's UTC date. The time is taken from the live UTC clock in the top right of the form at the moment you click Log QSO.\n\nTo enter a QSO from a paper log, enter the time manually in the HH and MM fields. A Reset to UTC button will appear — click it to return to the live clock."
            ),
            HelpItem(
                heading: "UTC Clock",
                body: "The live UTC clock in the top right of the entry form shows the current time in HH:mm:ss UTC format, updating every second. This is the time that will be logged when you click Log QSO, unless you have manually overridden the time."
            ),
            HelpItem(
                heading: "Station Callsign",
                body: "Your station callsign is set in Preferences (KitLog → Preferences) and is stored with each QSO. This is important when operating from multiple locations with different callsigns — for example /P operation."
            ),
            HelpItem(
                heading: "Editing and Deleting QSOs",
                body: "Right-click any QSO in the log table to see the context menu. For a single row this shows:\n\n• Look Up — opens the callsign lookup sheet\n• Edit QSO — opens the edit sheet\n• Delete QSO — deletes with confirmation\n\nYou can also double-click a row to open the edit sheet directly."
            ),
        ]
    ),

    HelpSection(
        id: "batch",
        title: "Batch Operations",
        icon: "checklist",
        content: [
            HelpItem(
                heading: "Selecting Multiple Rows",
                body: "Click a row to select it. Hold ⌘ and click to select additional rows, or hold ⇧ and click to select a range of rows."
            ),
            HelpItem(
                heading: "Batch Edit",
                body: "Select two or more rows, then either right-click and choose Batch Edit, or click the Batch Edit button that appears in the toolbar.\n\nThe batch edit sheet shows all editable fields with a checkbox next to each one. Only ticked fields will be updated — unticked fields are left unchanged.\n\nA confirmation dialog shows how many QSOs will be affected before applying."
            ),
            HelpItem(
                heading: "Batch Delete",
                body: "Select two or more rows, then right-click and choose Delete. A confirmation dialog will ask you to confirm before deleting.\n\nSingle row deletion also requires confirmation."
            ),
            HelpItem(
                heading: "Batch Editable Fields",
                body: "The following fields can be updated in a batch edit:\n\n• Station Callsign — useful when you forgot to set your /P callsign before a session\n• Band\n• Mode\n• RST Sent and Received\n• Operator Name\n• Notes"
            ),
        ]
    ),

    HelpSection(
        id: "lookup",
        title: "Callsign Lookup",
        icon: "magnifyingglass",
        content: [
            HelpItem(
                heading: "Looking Up a Callsign",
                body: "Right-click any QSO in the log table and choose Look Up [callsign] to open the callsign lookup sheet. The lookup opens inside KitLog as a sheet, showing the callsign information from your chosen lookup site."
            ),
            HelpItem(
                heading: "Choosing a Lookup Site",
                body: "You can choose which lookup site to use in KitLog → Preferences under Callsign Lookup. The available sites are:\n\n• 73QRZ — https://73qrz.com\n• QRZ.com — https://www.qrz.com\n• HamCall — https://hamcall.net\n• HamQTH — https://hamqth.com\n\nIf one site is unavailable, switch to another in Preferences."
            ),
        ]
    ),

    HelpSection(
        id: "duplicate",
        title: "Duplicate Detection",
        icon: "exclamationmark.triangle",
        content: [
            HelpItem(
                heading: "How it Works",
                body: "When dupe detection is enabled, KitLog checks for existing QSOs with the same callsign, band and mode within a configurable time window as you type in the entry form.\n\nIf a possible duplicate is found, an orange warning bar appears below the entry form showing the callsign, band, mode and time of the previous QSO."
            ),
            HelpItem(
                heading: "Enabling Dupe Detection",
                body: "Turn dupe detection on or off in KitLog → Preferences under Duplicate Detection. You can also configure the time window — the default is 30 minutes."
            ),
            HelpItem(
                heading: "Import Dupe Checking",
                body: "When importing an ADIF file, KitLog automatically checks for duplicates against your existing log. Any QSOs already in the log will be skipped, and the import summary will tell you how many were skipped."
            ),
            HelpItem(
                heading: "WSJT-X Dupe Checking",
                body: "QSOs received via the WSJT-X UDP listener are also dupe checked. If the same callsign is logged on the same band and mode within the same minute, the duplicate is silently ignored."
            ),
        ]
    ),

    HelpSection(
        id: "adif",
        title: "Import & Export",
        icon: "square.and.arrow.up.on.square",
        content: [
            HelpItem(
                heading: "Importing ADIF",
                body: "Go to File → Import ADIF and choose an ADIF file (.adi or .adif). KitLog supports standard ADIF files from most logging programs, as well as files from WSJT-X, JTDX and JS8Call.\n\nDuplicate QSOs are automatically detected and skipped during import. The import summary shows how many QSOs were imported and how many were skipped."
            ),
            HelpItem(
                heading: "Exporting ADIF",
                body: "Go to File → Export ADIF to export your entire log as an ADIF file. The export includes all fields including your station callsign, which is stored as STATION_CALLSIGN in the ADIF file.\n\nADIF files can be uploaded to QRZ, LoTW, eQSL, ClubLog and most other online logbooks."
            ),
            HelpItem(
                heading: "Supported ADIF Fields",
                body: "KitLog imports and exports the following ADIF fields: CALL, QSO_DATE, TIME_ON, BAND, MODE, SUBMODE, FREQ, RST_SENT, RST_RCVD, NAME, QTH, COMMENT, STATION_CALLSIGN.\n\nWhen importing from WSJT-X, the SUBMODE field is used to correctly identify FT8, FT4 and other digital modes."
            ),
        ]
    ),

    HelpSection(
        id: "wsjtx",
        title: "WSJT-X Integration",
        icon: "waveform.path",
        content: [
            HelpItem(
                heading: "UDP Listener",
                body: "KitLog can automatically log QSOs from WSJT-X, JTDX and JS8Call in real time using a UDP listener on port 2237.\n\nWhen a QSO is logged in WSJT-X, it is instantly added to KitLog and a blue confirmation flash appears in the entry form."
            ),
            HelpItem(
                heading: "Setting Up WSJT-X",
                body: "In WSJT-X, go to File → Settings → Reporting and make sure:\n• UDP Server is set to localhost or 127.0.0.1\n• UDP Server port is 2237\n• Accept UDP requests is checked\n\nThe same settings apply for JTDX and JS8Call."
            ),
            HelpItem(
                heading: "Enabling the Listener",
                body: "Turn the UDP listener on or off in KitLog → Preferences under WSJT-X Integration. A green dot indicates the listener is active and ready to receive QSOs."
            ),
            HelpItem(
                heading: "WSJT-X Online Indicator",
                body: "When the UDP listener is enabled, a small indicator appears in the entry form showing whether WSJT-X is online. This is based on heartbeat packets sent by WSJT-X every 15 seconds. If no heartbeat is received for 30 seconds, the indicator shows offline."
            ),
            HelpItem(
                heading: "Compatible Programs",
                body: "The following programs are compatible with KitLog's UDP listener as they use the same protocol as WSJT-X:\n\n• WSJT-X\n• JTDX\n• JS8Call\n\nNote that only one program can send to port 2237 at a time."
            ),
        ]
    ),

    HelpSection(
        id: "filtering",
        title: "Filtering & Search",
        icon: "line.3.horizontal.decrease.circle",
        content: [
            HelpItem(
                heading: "Filter Bar",
                body: "The filter bar above the log table lets you filter QSOs by callsign, band, mode, country and date range. Filters apply instantly as you type or select.\n\nWhen filters are active, the log header shows the number of matching QSOs out of the total — for example '47 of 1,669 contacts'."
            ),
            HelpItem(
                heading: "Callsign Filter",
                body: "Type a full or partial callsign in the Call field to filter the log. The search is case insensitive and matches anywhere in the callsign — for example 'G4' will match G4ABC, G4XYZ and so on."
            ),
            HelpItem(
                heading: "Date Range Filter",
                body: "Click the From or To buttons to set a date range. A date picker will appear — select the date and it will be applied immediately. Click the X next to a date to clear it."
            ),
            HelpItem(
                heading: "Reset Filters",
                body: "Click the orange Reset Filters button in the toolbar to clear all active filters and return to the full log. This also clears any filters applied by clicking in the Statistics panel."
            ),
        ]
    ),

    HelpSection(
        id: "stats",
        title: "Statistics Panel",
        icon: "chart.bar",
        content: [
            HelpItem(
                heading: "Opening the Panel",
                body: "Click the Statistics header at the bottom of the window to expand the statistics panel. Click it again to collapse it. The panel is collapsed by default."
            ),
            HelpItem(
                heading: "What's Shown",
                body: "The statistics panel shows your QSOs broken down by band, mode, most worked callsigns and country. Each section shows a progress bar indicating the proportion of your total QSOs.\n\nThe country breakdown is derived from the callsign prefix and covers over 200 DXCC entities."
            ),
            HelpItem(
                heading: "Filtering by Clicking",
                body: "Click any band, mode or country in the statistics panel to filter the log table to show only QSOs matching that selection. The selected item is highlighted in blue.\n\nClick the same item again to deselect it, or click Clear Stats Filter to remove the filter."
            ),
            HelpItem(
                heading: "Most Worked",
                body: "The Most Worked section shows the top 5 callsigns you have worked more than once. This reflects the currently filtered results — if you filter by band, it shows the most worked callsigns on that band."
            ),
        ]
    ),

    HelpSection(
        id: "preferences",
        title: "Preferences",
        icon: "gearshape",
        content: [
            HelpItem(
                heading: "Your Callsign",
                body: "Enter your station callsign in Preferences → Station. This is stored with every QSO you log and included in ADIF exports as STATION_CALLSIGN.\n\nIf you operate from multiple locations with different callsigns (for example /P operation), you can change this before operating and it will be applied to all new QSOs."
            ),
            HelpItem(
                heading: "Default RST",
                body: "Set default RST Sent and Received values in Preferences → Defaults. These are pre-filled in the entry form each time."
            ),
            HelpItem(
                heading: "Duplicate Detection",
                body: "Enable or disable duplicate detection and configure the time window in Preferences → Duplicate Detection. The time window defines how far back KitLog looks for duplicate QSOs — the default is 30 minutes."
            ),
            HelpItem(
                heading: "Callsign Lookup",
                body: "Choose your preferred callsign lookup site in Preferences → Callsign Lookup. The available sites are 73QRZ, QRZ.com, HamCall and HamQTH. If one site is unavailable, switch to another here."
            ),
            HelpItem(
                heading: "WSJT-X Integration",
                body: "Enable or disable the WSJT-X UDP listener in Preferences → WSJT-X Integration. The listener runs on port 2237 and is compatible with WSJT-X, JTDX and JS8Call."
            ),
        ]
    ),

    HelpSection(
        id: "shortcuts",
        title: "Keyboard Shortcuts",
        icon: "keyboard",
        content: [
            HelpItem(
                heading: "File Menu",
                body: "⌘⇧I — Import ADIF\n⌘⇧E — Export ADIF\n⌘, — Preferences\n⌘? — KitLog Help"
            ),
            HelpItem(
                heading: "Log Table",
                body: "Double-click — Edit QSO\nRight-click — Context menu (Look Up, Edit, Delete)\n⌘-click — Select multiple rows\n⇧-click — Select a range of rows"
            ),
            HelpItem(
                heading: "Column Sorting",
                body: "Click any column header to sort by that column. Click again to reverse the sort order. An arrow in the column header indicates the current sort column and direction."
            ),
        ]
    ),
]

// MARK: - Help View

struct HelpView: View {
    @State private var selectedSection = "getting-started"
    @Environment(\.dismiss) private var dismiss

    var currentSection: HelpSection? {
        helpSections.first { $0.id == selectedSection }
    }

    var body: some View {
        HStack(spacing: 0) {

            // Sidebar
            List(helpSections, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section.id)
            }
            .listStyle(.sidebar)
            .frame(width: 200)

            Divider()

            // Content
            if let section = currentSection {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            Image(systemName: section.icon)
                                .font(.largeTitle)
                                .foregroundColor(.accentColor)
                            Text(section.title)
                                .font(.largeTitle)
                                .bold()
                        }
                        .padding(.bottom, 8)

                        ForEach(section.content) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.heading)
                                    .font(.headline)
                                Text(item.body)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.quaternary.opacity(0.5),
                                        in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(24)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .navigationTitle("KitLog Help")
    }
}
