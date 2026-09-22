# Frame Timecode

Enable **Show Frames** in Controls or Settings → Display. Frame display uses 24-hour timecode and includes seconds.

Supported rates are 23.976, 24, 25, 29.97 NDF, 29.97 DF, 30, 50, 59.94 NDF, 59.94 DF and 60 FPS. Fractional rates use exact rational values.

Clock-mode timecode is based on local time since midnight. Fractional non-drop-frame (NDF) timecode differs from civil time. Drop-frame (DF) skips frame **labels**, not frames, at minute boundaries except every tenth minute; a semicolon identifies it.

Timer timecode uses elapsed or remaining duration. This is a local display, **not an LTC/MTC synchronization source**. System clock changes and daylight-saving transitions affect the display.

Offline city data comes from GeoNames (CC BY 4.0), with country/time-zone mapping from IANA. See the third-party notices bundled with the app.
