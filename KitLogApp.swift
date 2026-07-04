import SwiftUI
import SwiftData
import Combine

@main
struct KitLogApp: App {
    @StateObject private var appState = AppState()
    @State private var showingHelp = false
    
    var body: some Scene {
        WindowGroup {
            if appState.modelContainer == nil {
                SetupView(appState: appState)
            } else {
                ContentView()
                    .modelContainer(appState.modelContainer!)
                    .environmentObject(appState)
            }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Divider()
                Button("Import ADIF…") {
                    NotificationCenter.default.post(name: .importADIF, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Button("Export ADIF…") {
                    NotificationCenter.default.post(name: .exportADIF, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Divider()

                Button("Database Location…") {
                    NotificationCenter.default.post(name: .changeDatabase, object: nil)
                }
            }
            
            CommandGroup(replacing: .help) {
                Button("KitLog Help") {
                    NotificationCenter.default.post(name: .showHelp, object: nil)
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }

        Settings {
            PreferencesView()
        }
    }
}

// MARK: - AppState

class AppState: ObservableObject {
    @Published var modelContainer: ModelContainer?

    private let pathKey = "databaseFolderPath"

    init() {
        if let container = loadContainerFromSavedPath() {
            self.modelContainer = container
        }
    }

    func loadContainerFromSavedPath() -> ModelContainer? {
        guard let path = UserDefaults.standard.string(forKey: pathKey) else {
            return nil
        }
        let url = URL(fileURLWithPath: path)
        return try? makeContainer(in: url)
    }

    func setDatabaseFolder(_ url: URL, moveExisting: Bool) {
        do {
            if moveExisting, let existingURL = currentStoreURL() {
                let filesToMove = [
                    existingURL,
                    existingURL.appendingPathExtension("shm"),
                    existingURL.appendingPathExtension("wal")
                ]
                for file in filesToMove {
                    let dest = url.appendingPathComponent(file.lastPathComponent)
                    if FileManager.default.fileExists(atPath: file.path) {
                        try FileManager.default.moveItem(at: file, to: dest)
                    }
                }
            }

            let container = try makeContainer(in: url)
            UserDefaults.standard.set(url.path, forKey: pathKey)
            DispatchQueue.main.async {
                self.modelContainer = container
            }
        } catch {
            print("KitLog: could not set database folder: \(error)")
        }
    }

    func currentStoreURL() -> URL? {
        guard let path = UserDefaults.standard.string(forKey: pathKey) else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent("kitlog.store")
    }

    func makeContainer(in folder: URL) throws -> ModelContainer {
        let storeURL = folder.appendingPathComponent("kitlog.store")
        let config = ModelConfiguration(url: storeURL)
        return try ModelContainer(for: QSOEntry.self, configurations: config)
    }
}

// MARK: - Notification names

extension Notification.Name {
    static let importADIF     = Notification.Name("importADIF")
    static let exportADIF     = Notification.Name("exportADIF")
    static let changeDatabase = Notification.Name("changeDatabase")
    static let showHelp       = Notification.Name("showHelp")
}
