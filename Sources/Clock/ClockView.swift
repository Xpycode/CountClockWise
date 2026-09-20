import Cocoa

final class ClockView: NSView {
    private let timeLabel = NSTextField(labelWithString: "")
    private let dateLabel = NSTextField(labelWithString: "")
    private let zoneLabel = NSTextField(labelWithString: "")
    private var timer: Timer?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        setupLabels()
        applySettings()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(applySettings), name: .settingsDidChange, object: nil
        )
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private func setupLabels() {
        for label in [timeLabel, dateLabel, zoneLabel] {
            label.alignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
        }

        NSLayoutConstraint.activate([
            timeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            dateLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            dateLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),

            zoneLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            zoneLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 12),
        ])
    }

    @objc private func applySettings() {
        let s = Settings.shared
        layer?.backgroundColor = s.backgroundColor.cgColor
        timeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: CGFloat(s.fontSize), weight: .bold)
        timeLabel.textColor = s.textColor
        dateLabel.font = NSFont.systemFont(ofSize: CGFloat(s.fontSize) * 0.2, weight: .medium)
        dateLabel.textColor = s.textColor.withAlphaComponent(0.7)
        dateLabel.isHidden = !s.showDate
        zoneLabel.font = NSFont.systemFont(ofSize: CGFloat(s.fontSize) * 0.11, weight: .regular)
        zoneLabel.textColor = s.textColor.withAlphaComponent(0.4)
        zoneLabel.stringValue = s.timeZoneIdentifier
        tick()
    }

    private func tick() {
        let s = Settings.shared
        let now = Date()

        let timeFormatter = DateFormatter()
        timeFormatter.timeZone = s.timeZone
        timeFormatter.dateFormat = s.use24Hour
            ? (s.showSeconds ? "HH:mm:ss" : "HH:mm")
            : (s.showSeconds ? "h:mm:ss a" : "h:mm a")
        timeLabel.stringValue = timeFormatter.string(from: now)

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = s.timeZone
        dateFormatter.dateFormat = "EEEE, d MMMM yyyy"
        dateLabel.stringValue = dateFormatter.string(from: now)
    }
}
