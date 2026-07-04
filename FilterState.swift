import Foundation
import Combine

class FilterState: ObservableObject {
    @Published var band: String = "All"
    @Published var mode: String = "All"
    @Published var country: String = "All"

    func reset() {
        band = "All"
        mode = "All"
        country = "All"
    }

    var isActive: Bool {
        band != "All" || mode != "All" || country != "All"
    }
}
