import UIKit
import WebKit

final class BrowserViewController: UIViewController {

    // MARK: - Config

    private let homeURL = URL(string: "https://duckduckgo.com")!
    private let searchTemplate = "https://duckduckgo.com/?q=%@"

    // MARK: - Views

    private var webView: WKWebView!
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let urlField = UITextField()
    private let toolbar = UIToolbar()

    private lazy var backItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                                style: .plain, target: self, action: #selector(goBack))
    private lazy var forwardItem = UIBarButtonItem(image: UIImage(systemName: "chevron.right"),
                                                   style: .plain, target: self, action: #selector(goForward))
    private lazy var homeItem = UIBarButtonItem(image: UIImage(systemName: "house"),
                                                style: .plain, target: self, action: #selector(goHome))
    private lazy var reloadItem = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"),
                                                  style: .plain, target: self, action: #selector(reloadOrStop))
    private lazy var shareItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"),
                                                 style: .plain, target: self, action: #selector(sharePage))

    private var observations: [NSKeyValueObservation] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupWebView()
        setupChrome()
        setupObservers()
        load(url: homeURL)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .default }

    // MARK: - Setup

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.keyboardDismissMode = .onDrag
        view.addSubview(webView)
    }

    private func setupChrome() {
        // URL field
        urlField.translatesAutoresizingMaskIntoConstraints = false
        urlField.borderStyle = .roundedRect
        urlField.backgroundColor = .secondarySystemBackground
        urlField.placeholder = "Search or enter address"
        urlField.font = .systemFont(ofSize: 15)
        urlField.autocapitalizationType = .none
        urlField.autocorrectionType = .no
        urlField.spellCheckingType = .no
        urlField.keyboardType = .webSearch
        urlField.returnKeyType = .go
        urlField.clearButtonMode = .whileEditing
        urlField.delegate = self
        view.addSubview(urlField)

        // Progress
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .clear
        progressView.alpha = 0
        view.addSubview(progressView)

        // Toolbar
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        let flex = { UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) }
        toolbar.items = [backItem, flex(), forwardItem, flex(), homeItem, flex(), reloadItem, flex(), shareItem]
        view.addSubview(toolbar)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            urlField.topAnchor.constraint(equalTo: guide.topAnchor, constant: 6),
            urlField.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 10),
            urlField.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -10),
            urlField.heightAnchor.constraint(equalToConstant: 36),

            progressView.topAnchor.constraint(equalTo: urlField.bottomAnchor, constant: 4),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),

            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),

            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ])

        updateNavButtons()
    }

    private func setupObservers() {
        observations = [
            webView.observe(\.estimatedProgress, options: [.new]) { [weak self] wv, _ in
                self?.updateProgress(Float(wv.estimatedProgress), loading: wv.isLoading)
            },
            webView.observe(\.url, options: [.new]) { [weak self] wv, _ in
                guard let self = self, !self.urlField.isFirstResponder else { return }
                self.urlField.text = wv.url?.absoluteString
            },
            webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in self?.updateNavButtons() },
            webView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in self?.updateNavButtons() },
            webView.observe(\.isLoading, options: [.new]) { [weak self] _, _ in self?.updateNavButtons() }
        ]
    }

    // MARK: - Navigation

    private func load(url: URL) {
        webView.load(URLRequest(url: url))
    }

    /// Turns whatever the user typed into either a URL or a search query.
    private func resolve(_ text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), url.scheme == "http" || url.scheme == "https" {
            return url
        }

        // Looks like a bare domain (has a dot, no spaces) -> prepend https
        let looksLikeDomain = trimmed.contains(".")
            && !trimmed.contains(" ")
            && !trimmed.hasSuffix(".")
        if looksLikeDomain, let url = URL(string: "https://" + trimmed) {
            return url
        }

        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        return URL(string: String(format: searchTemplate, encoded))
    }

    @objc private func goBack() { if webView.canGoBack { webView.goBack() } }
    @objc private func goForward() { if webView.canGoForward { webView.goForward() } }
    @objc private func goHome() { load(url: homeURL) }

    @objc private func reloadOrStop() {
        if webView.isLoading { webView.stopLoading() } else { webView.reload() }
    }

    @objc private func sharePage() {
        guard let url = webView.url else { return }
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        sheet.popoverPresentationController?.barButtonItem = shareItem
        present(sheet, animated: true)
    }

    // MARK: - UI state

    private func updateNavButtons() {
        backItem.isEnabled = webView.canGoBack
        forwardItem.isEnabled = webView.canGoForward
        reloadItem.image = UIImage(systemName: webView.isLoading ? "xmark" : "arrow.clockwise")
        shareItem.isEnabled = webView.url != nil
    }

    private func updateProgress(_ value: Float, loading: Bool) {
        progressView.setProgress(value, animated: true)
        if loading {
            progressView.alpha = 1
        } else {
            UIView.animate(withDuration: 0.3, animations: { self.progressView.alpha = 0 }) { _ in
                self.progressView.setProgress(0, animated: false)
            }
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Can't load page", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension BrowserViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        DispatchQueue.main.async { textField.selectAll(nil) }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let url = resolve(textField.text ?? "") {
            load(url: url)
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if (textField.text ?? "").isEmpty { textField.text = webView.url?.absoluteString }
    }
}

// MARK: - WKNavigationDelegate / WKUIDelegate

extension BrowserViewController: WKNavigationDelegate, WKUIDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if !urlField.isFirstResponder { urlField.text = webView.url?.absoluteString }
        updateNavButtons()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    private func handle(_ error: Error) {
        let nsError = error as NSError
        // Ignore user-initiated cancels
        guard nsError.code != NSURLErrorCancelled else { return }
        showError(nsError.localizedDescription)
    }

    /// Open target="_blank" links in the same web view instead of dropping them.
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    /// Hand off tel:, mailto:, and app links to the system.
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() else {
            decisionHandler(.allow); return
        }
        if scheme == "http" || scheme == "https" || scheme == "about" || scheme == "data" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        }
    }
}
