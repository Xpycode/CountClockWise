import Foundation
import OSLog

/// Local diagnostics only. Callers supply static event names, never user content.
final class DiagnosticLogger {
    static let shared = DiagnosticLogger(directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Clock", isDirectory: true))

    let logURL: URL
    private let backupURL: URL
    private let maxFileBytes: Int
    private let queue = DispatchQueue(label: "com.lucesumbrarum.Clock.diagnostics")
    private var failure: String?
    private let fallback = Logger(subsystem: "com.lucesumbrarum.Clock", category: "Diagnostics")

    init(directory: URL, maxFileBytes: Int = 131_072) {
        logURL = directory.appendingPathComponent("diagnostics.log")
        backupURL = directory.appendingPathComponent("diagnostics.previous.log")
        self.maxFileBytes = max(256, maxFileBytes)
    }

    var lastFailure: String? { queue.sync { failure } }

    /// Writes asynchronously so logging cannot delay countdown updates.
    func record(_ event: StaticString, error: Error? = nil) {
        let details = error.map { " error=\(Self.safeError($0))" } ?? ""
        queue.async {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let message = "\(timestamp) \(event)\(details)"
            // Keep each record bounded, valid UTF-8 and on one line.
            var bytes = Array(message.replacingOccurrences(of: "\n", with: " ").utf8.prefix(self.maxFileBytes - 1))
            while String(bytes: bytes, encoding: .utf8) == nil { bytes.removeLast() }
            bytes.append(10)
            do {
                let fm = FileManager.default
                try fm.createDirectory(at: self.logURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                let size = (try? fm.attributesOfItem(atPath: self.logURL.path)[.size] as? NSNumber)?.intValue ?? 0
                if size + bytes.count > self.maxFileBytes {
                    if fm.fileExists(atPath: self.backupURL.path) { try fm.removeItem(at: self.backupURL) }
                    try fm.moveItem(at: self.logURL, to: self.backupURL)
                }
                if !fm.fileExists(atPath: self.logURL.path) {
                    try Data().write(to: self.logURL, options: .atomic)
                }
                let handle = try FileHandle(forWritingTo: self.logURL)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: Data(bytes))
                self.failure = nil
            } catch {
                self.failure = "Diagnostic log unavailable (\(Self.safeError(error)))."
                self.fallback.error("Diagnostic file write failed: \(Self.safeError(error), privacy: .public)")
            }
        }
    }

    /// Waits for queued writes, then returns a bounded tail across both retained files.
    func recentTail(maxBytes: Int = 6000) -> String {
        queue.sync {
            let limit = max(0, min(maxBytes, maxFileBytes * 2))
            guard limit > 0 else { return "" }
            do {
                var data = Data()
                for url in [backupURL, logURL] where FileManager.default.fileExists(atPath: url.path) {
                    let handle = try FileHandle(forReadingFrom: url)
                    defer { try? handle.close() }
                    let size = try handle.seekToEnd()
                    try handle.seek(toOffset: size > UInt64(limit) ? size - UInt64(limit) : 0)
                    data.append(try handle.read(upToCount: limit) ?? Data())
                }
                var bytes = Array(data.suffix(limit))
                // A byte-limited tail may begin inside a multibyte character.
                while !bytes.isEmpty && String(bytes: bytes, encoding: .utf8) == nil { bytes.removeFirst() }
                return String(bytes: bytes, encoding: .utf8) ?? ""
            } catch {
                failure = "Diagnostic log unavailable (\(Self.safeError(error)))."
                return ""
            }
        }
    }

    private static func safeError(_ error: Error) -> String {
        let nsError = error as NSError
        let allowed = [NSCocoaErrorDomain, NSPOSIXErrorDomain, NSOSStatusErrorDomain, NSURLErrorDomain, "UNErrorDomain"]
        let domain = allowed.contains(nsError.domain) ? nsError.domain : "OtherError"
        return "\(domain):\(nsError.code)"
    }
}
