import SwiftUI
import AppKit

struct SetupView: View {
    @ObservedObject var appState: AppState
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Welcome to KitLog")
                .font(.largeTitle)
                .bold()

            Text("Before you start logging, please choose a folder where KitLog will store your database.\n\nTo sync across multiple Macs, choose a folder inside your iCloud Drive.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 380)

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }

            Button {
                chooseFolder()
            } label: {
                Label("Choose Database Folder…", systemImage: "folder.badge.plus")
                    .frame(minWidth: 220)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(48)
        .frame(minWidth: 500, minHeight: 380)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose Folder"
        panel.message = "Choose a folder for your KitLog database. For multi-Mac sync, pick a folder in iCloud Drive."

        guard panel.runModal() == .OK, let url = panel.url else { return }

        // Test we can write there
        let testFile = url.appendingPathComponent(".kitlog_test")
        do {
            try "test".write(to: testFile, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: testFile)
        } catch {
            errorMessage = "Cannot write to that folder: \(error.localizedDescription)\n\nPlease choose a different folder."
            return
        }

        appState.setDatabaseFolder(url, moveExisting: false)

        if appState.modelContainer == nil {
            errorMessage = "Could not create database at that location. Please try a different folder."
        }
    }
}
