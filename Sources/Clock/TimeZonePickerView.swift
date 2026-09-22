import Cocoa

struct TimeZoneEntry {
    let identifier: String
    let country: String
    var cityName: String? = nil
    var asciiName: String = ""
    var region: String { identifier.split(separator: "/").first.map(String.init) ?? "Other" }
    var city: String { cityName ?? identifier.split(separator: "/").dropFirst().joined(separator: " / ").replacingOccurrences(of: "_", with: " ") }
    var title: String { country.isEmpty ? (city.isEmpty ? identifier : city) : "\(city), \(country)" }
    var zone: TimeZone { TimeZone(identifier: identifier)! }

    static func abbreviation(for zone: TimeZone, at date: Date) -> String {
        zone.localizedName(for: zone.isDaylightSavingTime(for: date) ? .shortDaylightSaving : .shortStandard,
                           locale: Locale(identifier: "en_GB")) ?? zone.abbreviation(for: date) ?? zone.identifier
    }

    static func detail(for zone: TimeZone, at date: Date) -> String {
        let offset = zone.secondsFromGMT(for: date)
        let minutes = abs(offset) / 60
        return "\(abbreviation(for: zone, at: date)) · " + String(format: "UTC%@%02d:%02d", offset < 0 ? "−" : "+", minutes / 60, minutes % 60)
    }

    static func clockLabel(for zone: TimeZone, at date: Date) -> String {
        let city = zone.identifier.split(separator: "/").last.map(String.init)?.replacingOccurrences(of: "_", with: " ") ?? zone.identifier
        return "\(city) · \(abbreviation(for: zone, at: date))"
    }

    func matches(_ query: String, at date: Date) -> Bool {
        let names = [identifier, title, asciiName, region, Self.detail(for: zone, at: date),
                     zone.localizedName(for: .shortStandard, locale: Locale(identifier: "en_GB")) ?? "",
                     zone.localizedName(for: .shortDaylightSaving, locale: Locale(identifier: "en_GB")) ?? ""]
        let haystack = names.joined(separator: " ").replacingOccurrences(of: "_", with: " ")
        return query.split(whereSeparator: { $0.isWhitespace }).allSatisfy {
            haystack.range(of: String($0), options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    func matchesCity(_ query: String) -> Bool {
        let haystack = [title, asciiName, region, identifier].joined(separator: " ")
        return query.split(whereSeparator: { $0.isWhitespace }).allSatisfy {
            haystack.range(of: String($0), options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    static let cities: [TimeZoneEntry] = {
        guard let url = Bundle.module.url(forResource: "cities", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rows = try? JSONDecoder().decode([[String]].self, from: data) else { return [] }
        var countries: [String: String] = [:]
        var valid: [String: Bool] = [:]
        var seen = Set<String>()
        return rows.compactMap { row in
            guard row.count == 4 else { return nil }
            if valid[row[3]] == nil { valid[row[3]] = TimeZone(identifier: row[3]) != nil }
            guard valid[row[3]] == true, seen.insert(row[0] + row[2] + row[3]).inserted else { return nil }
            if countries[row[2]] == nil { countries[row[2]] = Locale.current.localizedString(forRegionCode: row[2]) ?? row[2] }
            return TimeZoneEntry(identifier: row[3], country: countries[row[2]]!, cityName: row[0], asciiName: row[1])
        }
    }()

    static func catalog() -> [Self] {
        // Public-domain IANA country mapping bundled with the app; Foundation supplies live rules.
        let data = Bundle.module.url(forResource: "zone", withExtension: "tab")
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
        var countries: [String: String] = [:]
        for line in data.split(separator: "\n") where !line.hasPrefix("#") {
            let fields = line.split(separator: "\t")
            guard fields.count >= 3 else { continue }
            countries[String(fields[2])] = Locale.current.localizedString(forRegionCode: String(fields[0])) ?? String(fields[0])
        }
        return Set(TimeZone.knownTimeZoneIdentifiers + ["UTC"] + Array(countries.keys))
            .filter { TimeZone(identifier: $0) != nil }
            .map { Self(identifier: $0, country: countries[$0] ?? "") }
            .sorted { ($0.region, $0.title) < ($1.region, $1.title) }
    }
}

final class TimeZonePickerView: NSView, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    private let settings: Settings
    private let favouritesOnly = NSButton(checkboxWithTitle: "Favourites only", target: nil, action: nil)
    private let favourite = NSButton(title: "Favourite Selected Zone", target: nil, action: nil)
    private let search = NSSearchField()
    private let regions = NSPopUpButton()
    private let system = NSButton(checkboxWithTitle: "Use System Time Zone", target: nil, action: nil)
    private let summary = NSTextField(labelWithString: "")
    private let table = NSTableView()
    private let empty = NSTextField(labelWithString: "No matching time zones")
    private let entries = TimeZoneEntry.catalog()
    private var rows: [(heading: String?, entry: TimeZoneEntry?)] = []
    private var refreshing = false
    private var refreshTimer: Timer?

    init(settings: Settings = .shared) {
        self.settings = settings
        super.init(frame: .zero)
        system.target = self
        system.action = #selector(useSystem)
        search.placeholderString = "Search city, country, region or abbreviation"
        search.delegate = self
        search.sendsSearchStringImmediately = true
        search.setAccessibilityLabel("Search time zones")
        regions.addItem(withTitle: "All Regions")
        regions.addItems(withTitles: Array(Set(entries.map(\.region))).sorted())
        regions.target = self
        regions.action = #selector(filterChanged)
        let controls = NSStackView(views: [search, regions])
        controls.orientation = .horizontal
        controls.spacing = 8
        summary.font = .systemFont(ofSize: 12)
        summary.textColor = .secondaryLabelColor
        summary.lineBreakMode = .byTruncatingMiddle
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("zone"))
        table.addTableColumn(column)
        table.headerView = nil
        table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        table.delegate = self
        table.dataSource = self
        table.rowHeight = 44
        table.allowsEmptySelection = true
        table.setAccessibilityLabel("Time zones")
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        favouritesOnly.target = self; favouritesOnly.action = #selector(filterChanged)
        favourite.target = self; favourite.action = #selector(toggleFavourite)
        let favouritesRow = NSStackView(views: [favouritesOnly, favourite])
        let credit = NSTextField(labelWithString: "City data: GeoNames · CC BY 4.0")
        credit.font = .systemFont(ofSize: 10); credit.textColor = .secondaryLabelColor
        let stack = NSStackView(views: [system, summary, controls, favouritesRow, scroll, credit])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        empty.translatesAutoresizingMaskIntoConstraints = false
        empty.textColor = .secondaryLabelColor
        addSubview(empty)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            controls.widthAnchor.constraint(equalTo: stack.widthAnchor),
            summary.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scroll.widthAnchor.constraint(equalTo: stack.widthAnchor),
            search.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),
            empty.centerXAnchor.constraint(equalTo: scroll.centerXAnchor),
            empty.centerYAnchor.constraint(equalTo: scroll.centerYAnchor)
        ])
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .settingsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSNotification.Name.NSSystemTimeZoneDidChange, object: nil)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self, self.window?.isVisible == true else { return }
            self.refresh()
        }
        refresh()
    }

    required init?(coder: NSCoder) { fatalError() }
    deinit { refreshTimer?.invalidate(); NotificationCenter.default.removeObserver(self) }
    @objc private func toggleFavourite() {
        var favourites = Set(UserDefaults.standard.stringArray(forKey: "favouriteZones") ?? [])
        let identifier = settings.timeZone.identifier
        if favourites.contains(identifier) { favourites.remove(identifier) } else { favourites.insert(identifier) }
        UserDefaults.standard.set(favourites.sorted(), forKey: "favouriteZones")
        refresh()
    }
    @objc private func useSystem() { settings.usesSystemTimeZone = system.state == .on }
    @objc private func filterChanged() { refresh() }
    func controlTextDidChange(_ obj: Notification) { refresh() }

    @objc private func refresh() {
        refreshing = true
        defer { refreshing = false }
        let now = Date()
        system.state = settings.usesSystemTimeZone ? .on : .off
        summary.stringValue = "Selected: \(settings.timeZone.identifier) — \(TimeZoneEntry.detail(for: settings.timeZone, at: now))"
        let favourites = Set(UserDefaults.standard.stringArray(forKey: "favouriteZones") ?? [])
        favourite.title = favourites.contains(settings.timeZone.identifier) ? "Remove Selected Favourite" : "Favourite Selected Zone"
        let query = search.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        var candidates = entries.filter { $0.matches(query, at: now) }
        if !query.isEmpty && favouritesOnly.state == .off {
            let matches = TimeZoneEntry.cities.filter { $0.matchesCity(query) }
            var seen = Set(candidates.map { $0.identifier + $0.city })
            candidates += matches.filter { seen.insert($0.identifier + $0.city).inserted }
        }
        let filtered = candidates.filter {
            (regions.indexOfSelectedItem == 0 || $0.region == regions.titleOfSelectedItem)
                && (favouritesOnly.state == .off || favourites.contains($0.identifier))
        }
        let sorted = filtered.sorted { ($0.region, $0.title) < ($1.region, $1.title) }
        rows = []
        var region = ""
        for entry in sorted {
            if entry.region != region { region = entry.region; rows.append((region, nil)) }
            rows.append((nil, entry))
        }
        empty.isHidden = !filtered.isEmpty
        table.reloadData()
        if !settings.usesSystemTimeZone, let index = rows.firstIndex(where: { $0.entry?.identifier == settings.timeZoneIdentifier && (settings.selectedCity.isEmpty || $0.entry?.city == settings.selectedCity) }) {
            table.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        } else { table.deselectAll(nil) }
    }

    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool { rows[row].entry != nil }
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool { rows[row].heading != nil }
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat { rows[row].entry == nil ? 24 : 44 }
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !refreshing, rows.indices.contains(table.selectedRow), let entry = rows[table.selectedRow].entry else { return }
        settings.timeZoneIdentifier = entry.identifier
        settings.selectedCity = entry.city
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let heading = rows[row].heading {
            let label = NSTextField(labelWithString: heading)
            label.font = .boldSystemFont(ofSize: 12)
            return label
        }
        guard let entry = rows[row].entry else { return nil }
        let selected = !settings.usesSystemTimeZone && entry.identifier == settings.timeZoneIdentifier
            && (settings.selectedCity.isEmpty || settings.selectedCity == entry.city)
        let title = NSTextField(labelWithString: (selected ? "✓ " : "") + entry.title)
        let detail = NSTextField(labelWithString: TimeZoneEntry.detail(for: entry.zone, at: Date()))
        title.lineBreakMode = .byTruncatingTail
        detail.font = .systemFont(ofSize: 11)
        detail.textColor = .secondaryLabelColor
        let stack = NSStackView(views: [title, detail])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 2
        return stack
    }
}
