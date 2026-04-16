import Foundation

final class UpdateService: NSObject, URLSessionDownloadDelegate {

    private let apiURL = URL(string: "https://api.github.com/repos/Papusha32/Rift/releases/latest")!
    private let currentVersion: String
    private var progressHandler: ((Double) -> Void)?
    private var downloadContinuation: CheckedContinuation<URL, Error>?

    init(currentVersion: String? = nil) {
        self.currentVersion = currentVersion
            ?? (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0")
        super.init()
    }

    // MARK: - Check

    func checkForUpdate() async throws -> (version: String, url: URL)? {
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        // 404 = no releases yet, treat as up-to-date
        if let http = response as? HTTPURLResponse, http.statusCode == 404 { return nil }

        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        guard VersionComparator.isNewer(release.version, than: currentVersion),
              let url = release.dmgURL else { return nil }
        return (release.version, url)
    }

    // MARK: - Download

    func downloadUpdate(from url: URL, progress: @escaping (Double) -> Void) async throws -> URL {
        self.progressHandler = progress
        return try await withCheckedThrowingContinuation { continuation in
            self.downloadContinuation = continuation
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            session.downloadTask(with: url).resume()
        }
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent("Rift-update.dmg")
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.moveItem(at: location, to: dest)
            downloadContinuation?.resume(returning: dest)
        } catch {
            downloadContinuation?.resume(throwing: error)
        }
        downloadContinuation = nil
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        progressHandler?(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            downloadContinuation?.resume(throwing: error)
            downloadContinuation = nil
        }
    }
}
