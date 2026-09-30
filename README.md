# AwakeTray
Make your Mac not fall asleep

A menu bar eye that keeps your Mac awake.

- **Click** the eye to open the settings: how long to stay awake, and whether the display stays on too.
- **Double-click** the eye to start or stop right away.

| Icon | Meaning |
| --- | --- |
| Closed eye | Off, the Mac can sleep |
| Open eye with a blue bar | Keeping awake for a set time; the bar shows the time left |
| Eye with veins | Keeping awake until you stop it |

![Tray icons](docs/tray-icons.png)

## Build

Requires macOS 13 or later and the Swift toolchain (Xcode or the Command Line Tools).

```sh
Scripts/build-app.sh      # builds build/AwakeTray.app
open build/AwakeTray.app
```

The icons are drawn in code (`Sources/AwakeTray/TrayIcon.swift`). After changing them, run
`Scripts/generate-icons.sh` to refresh `Resources/AppIcon.icns` and the previews in `docs/`.
