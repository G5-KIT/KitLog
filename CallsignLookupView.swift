import SwiftUI
import WebKit

// MARK: - WKWebView wrapper

struct WebView: NSViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        // Load URL once here, not in updateNSView
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Do nothing here — prevents reloading on every SwiftUI redraw
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool

        init(isLoading: Binding<Bool>) {
            _isLoading = isLoading
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }
    }
}

// MARK: - Callsign Lookup View

struct CallsignLookupView: View {
    let callsign: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @ObservedObject private var settings = AppSettings.shared

    var lookupURL: URL? {
        let urlString: String
        switch settings.lookupSite {
        case "QRZ.com":
            urlString = "https://www.qrz.com/db/\(callsign)"
        case "HamCall":
            urlString = "https://hamcall.net/call?callsign=\(callsign)"
        case "HamQTH":
            urlString = "https://hamqth.com/\(callsign)"
        default:
            urlString = "https://73qrz.com/lookup?call=\(callsign)"
        }
        return URL(string: urlString)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Callsign Lookup — \(callsign)")
                        .font(.headline)
                    Text(settings.lookupSite)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.trailing, 8)
                }

                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            if let url = lookupURL {
                WebView(url: url, isLoading: $isLoading)
            } else {
                ContentUnavailableView(
                    "Invalid URL",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Could not generate a lookup URL for \(callsign)")
                )
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
