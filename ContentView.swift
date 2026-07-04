import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var allQSOs: [QSOEntry]
    @State private var showingMoveDialog = false
    @State private var pendingURL: URL?
    @State private var showingHelp = false
    @StateObject private var filterState = FilterState()

    var body: some View {
        VStack(spacing: 0) {
            QSOEntryForm()
            Divider()
            QSOLogView()
        }
        .frame(minWidth: 1000, minHeight: 650)
        .environmentObject(filterState)
        .onAppear {
            WsjtxWatcher.shared.start(modelContext: modelContext)
            migrateCountries()
        }
        .onDisappear {
            WsjtxWatcher.shared.stop()
        }
        .onReceive(NotificationCenter.default.publisher(for: .changeDatabase)) { _ in
            chooseNewFolder()
        }
        .confirmationDialog(
            "Move Existing Database?",
            isPresented: $showingMoveDialog,
            titleVisibility: .visible
        ) {
            Button("Move to New Location") {
                if let url = pendingURL {
                    appState.setDatabaseFolder(url, moveExisting: true)
                }
            }
            Button("Leave in Current Location") {
                if let url = pendingURL {
                    appState.setDatabaseFolder(url, moveExisting: false)
                }
            }
            Button("Cancel", role: .cancel) {
                pendingURL = nil
            }
        } message: {
            Text("Do you want to move your existing KitLog database to the new location, or leave it where it is and start fresh?")
        }
        
        .sheet(isPresented: $showingHelp) {
            NavigationStack {
                HelpView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showHelp)) { _ in
            showingHelp = true
        }
    }

    private func migrateCountries() {
        let needsMigration = allQSOs.filter { $0.country.isEmpty }
        guard !needsMigration.isEmpty else { return }
        print("KitLog: migrating country for \(needsMigration.count) QSOs…")
        for qso in needsMigration {
            qso.country = PrefixLookup.country(for: qso.callsign)
        }
        print("KitLog: country migration complete")
    }

    private func chooseNewFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose Folder"
        panel.message = "Choose a new folder for your KitLog database."

        guard panel.runModal() == .OK, let url = panel.url else { return }
        pendingURL = url
        showingMoveDialog = true
    }
}
