import Foundation

struct FrameRate: Equatable {
    let id: String
    let numerator: Int
    let denominator: Int
    let nominal: Int
    let drop: Int
    var fps: Double { Double(numerator) / Double(denominator) }
    var title: String { id + " FPS" }
    static let all: [FrameRate] = [
        .init(id: "23.976", numerator: 24000, denominator: 1001, nominal: 24, drop: 0),
        .init(id: "24", numerator: 24, denominator: 1, nominal: 24, drop: 0),
        .init(id: "25", numerator: 25, denominator: 1, nominal: 25, drop: 0),
        .init(id: "29.97 NDF", numerator: 30000, denominator: 1001, nominal: 30, drop: 0),
        .init(id: "29.97 DF", numerator: 30000, denominator: 1001, nominal: 30, drop: 2),
        .init(id: "30", numerator: 30, denominator: 1, nominal: 30, drop: 0),
        .init(id: "50", numerator: 50, denominator: 1, nominal: 50, drop: 0),
        .init(id: "59.94 NDF", numerator: 60000, denominator: 1001, nominal: 60, drop: 0),
        .init(id: "59.94 DF", numerator: 60000, denominator: 1001, nominal: 60, drop: 4),
        .init(id: "60", numerator: 60, denominator: 1, nominal: 60, drop: 0)
    ]
    static func named(_ id: String) -> FrameRate { all.first { $0.id == id } ?? all[2] }

    func timecode(frameCount: Int, wrap24Hours: Bool = false) -> String {
        var frames = max(0, frameCount)
        let perTenMinutes = nominal * 600 - drop * 9
        if wrap24Hours { frames %= perTenMinutes * 6 * 24 }
        if drop > 0 {
            let tens = frames / perTenMinutes
            let remainder = frames % perTenMinutes
            frames += drop * 9 * tens
            if remainder >= drop { frames += drop * ((remainder - drop) / (nominal * 60 - drop)) }
        }
        return String(format: "%02d:%02d:%02d%@%02d", frames / (nominal * 3600),
                      (frames / (nominal * 60)) % 60, (frames / nominal) % 60,
                      drop > 0 ? ";" : ":", frames % nominal)
    }

    func timecode(seconds: Double, wrap24Hours: Bool = false) -> String {
        timecode(frameCount: Int(floor(max(0, seconds) * fps + 0.000001)), wrap24Hours: wrap24Hours)
    }
}

struct ClockTimerState: Codable {
    var accumulated: TimeInterval = 0
    var startedAt: Date?
    var duration: TimeInterval = 300
    var completionDelivered = false
    var isRunning: Bool { startedAt != nil }
    func elapsed(at now: Date) -> TimeInterval {
        accumulated + (startedAt.map { max(0, now.timeIntervalSince($0)) } ?? 0)
    }
    func remaining(at now: Date) -> TimeInterval { max(0, duration - elapsed(at: now)) }
    mutating func toggle(at now: Date) {
        if startedAt != nil { accumulated = elapsed(at: now); startedAt = nil }
        else { startedAt = now }
    }
    mutating func reset() { accumulated = 0; startedAt = nil; completionDelivered = false }
    static func parseDuration(_ input: String) -> TimeInterval? {
        let parts = input.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ":", omittingEmptySubsequences: false)
        guard (1...3).contains(parts.count), parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }),
              let values = Optional(parts.compactMap { Int($0) }), values.count == parts.count else { return nil }
        if parts.count > 1 && values.dropFirst().contains(where: { $0 >= 60 }) { return nil }
        let seconds = values.reduce(0.0) { $0 * 60 + Double($1) }
        return seconds > 0 && seconds <= 604800 ? seconds : nil
    }
    static func display(seconds: Double) -> String {
        let total = Int(max(0, seconds))
        return String(format: "%02d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
    }
}
