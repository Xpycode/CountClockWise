# Third-party data

City data is derived from GeoNames cities15000.zip, downloaded 2026-09-22.
https://www.geonames.org/ · https://download.geonames.org/export/dump/
Licensed under Creative Commons Attribution 4.0:
https://creativecommons.org/licenses/by/4.0/
Changes: extracted city name, ASCII name, country code and time-zone identifier;
removed all other fields and converted the result to compact JSON. No endorsement implied.

The IANA zone.tab country mapping is public-domain tz database data, copied from
macOS on 2026-09-22. Its original notices remain in Sources/Clock/Resources/zone.tab.
Foundation and the installed operating system provide time-zone/DST rules.

## Software components

Sparkle 2.10.0 (MIT), MarkdownUI 2.4.1 (MIT), NetworkImage 6.0.1 (MIT), and
swift-cmark 0.9.0 (BSD-style notices and incorporated component notices) are
included under their respective licenses. Complete license texts are bundled
in Clock's resource bundle under Licenses and tracked in Sources/Clock/Resources/Licenses.

The user's shared HelpMenu, AppCitizenshipKit and FeedbackKit components are
vendored under Vendor; see Vendor/README.md for snapshot provenance.
