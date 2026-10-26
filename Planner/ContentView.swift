import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var errorMessage: String?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        
        // Pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(refreshControl:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
        
        context.coordinator.webView = webView
        
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20.0)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        weak var webView: WKWebView?
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        @objc func handleRefresh(refreshControl: UIRefreshControl) {
            webView?.reload()
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.errorMessage = nil
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                webView.scrollView.refreshControl?.endRefreshing()
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.errorMessage = error.localizedDescription
                webView.scrollView.refreshControl?.endRefreshing()
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.errorMessage = error.localizedDescription
                webView.scrollView.refreshControl?.endRefreshing()
            }
        }
    }
}

struct ContentView: View {
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var errorMessage: String? = nil
    
    let plannerURL = URL(string: "https://plan.77-67-89-87.sslip.io")!
    
    var body: some View {
        ZStack {
            WebView(url: plannerURL, isLoading: , canGoBack: , errorMessage: )
                .edgesIgnoringSafeArea(.bottom)
            
            if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text("Нет связи с сервером")
                        .font(.title3)
                        .bold()
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Button(action: {
                        errorMessage = nil
                        isLoading = true
                    }) {
                        Text("Повторить попытку")
                            .bold()
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
            }
            
            if isLoading && errorMessage == nil {
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground).opacity(0.4))
            }
        }
    }
}
