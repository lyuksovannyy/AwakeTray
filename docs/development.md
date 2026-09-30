# Development

AwakeTray is a Swift package with a single executable target, wrapped into an `.app` bundle by a
shell script. There is no Xcode project; open `Package.swift` in Xcode if you want an IDE.

## Requirements

- macOS 13 or later
- A Swift toolchain: Xcode, or the Command Line Tools (`xcode-select --install`)

## Build and run

```sh
Scripts/build-app.sh
open build/AwakeTray.app
```

The script builds in release mode, assembles `build/AwakeTray.app` from the binary,
`Resources/Info.plist` and `Resources/AppIcon.icns`, and signs it ad hoc.

- Extra arguments are passed to `swift build`. `--arch arm64 --arch x86_64` makes a universal
  binary; that needs full Xcode, not just the Command Line Tools.
- `VERSION=1.2.0 Scripts/build-app.sh` stamps that version into the bundle.

To make the installer disk image (the app plus a shortcut to Applications), run
`Scripts/build-dmg.sh` afterwards; it writes `build/AwakeTray.dmg`.

`open` does nothing visible if AwakeTray is already running. Quit the old copy first
(`pkill -x AwakeTray`) to try a new build.

## Layout

| Path | What it is |
| --- | --- |
| `Sources/AwakeTray/AppDelegate.swift` | Entry point, menu bar item, click handling, settings popover |
| `Sources/AwakeTray/AwakeController.swift` | Settings, the countdown, and the power assertion |
| `Sources/AwakeTray/ConfigView.swift` | SwiftUI settings view shown in the popover |
| `Sources/AwakeTray/TrayIcon.swift` | Draws the menu bar icon for each state |
| `Scripts/IconGen/main.swift` | Draws the app icon and renders the previews |
| `Resources/` | `Info.plist` and the generated `AppIcon.icns` |
| `docs/` | Documentation and the generated icon previews |

## How it works

**Staying awake.** `AwakeController` holds an IOKit power assertion while a session is active:
`PreventUserIdleDisplaySleep` when the display should stay on, otherwise
`PreventUserIdleSystemSleep`. Stopping, quitting, or the countdown reaching zero releases it.
Changing a setting mid-session restarts the session so the new values take effect.

**Clicks.** The menu bar button reports mouse-down events. A first click schedules the popover
to open after 0.25 seconds; a second click within that time cancels it and toggles the session
instead. If the second click arrives late, the popover that already opened is closed again.

**Icon.** `TrayIcon` draws into a 22 x 18 point canvas with Core Graphics. The closed eye is a
template image, so macOS tints it for light and dark menu bars. The two active states carry
colour (the blue bar, the reddish veins) and are drawn with the label colour of the menu bar's
current appearance. `AppDelegate` redraws the icon whenever the session or the clock changes.

**Open at login.** The toggle in `ConfigView` registers or unregisters the app bundle with
`SMAppService.mainApp` and then shows whatever status the system reports.

**No Dock icon.** The app runs with the accessory activation policy and `LSUIElement` set in
`Info.plist`.

## Icons

Both the menu bar icon and the app icon are drawn in code, so nothing is edited by hand. After
changing `TrayIcon.swift` or `Scripts/IconGen/main.swift`, regenerate the outputs:

```sh
Scripts/generate-icons.sh
```

This rewrites `Resources/AppIcon.icns`, `docs/app-icon.png` and `docs/tray-icons.png`. The tray
preview shows each state at 8x and at real retina size, on a dark and a light menu bar.
`TrayIcon.veinRedness` controls how red the veins are.

## Releasing

`.github/workflows/release.yml` runs when a tag starting with `v` is pushed. It builds a
universal app on a macOS runner, stamps the version from the tag, packs it into a disk image and
creates a GitHub release with the image attached and generated notes. Pushing a tag that already
has a release replaces the download instead.

```sh
git tag v1.0.0
git push origin v1.0.0
```

Releases are signed ad hoc and not notarized, so users see a Gatekeeper warning on first launch
(see [Troubleshooting](troubleshooting.md)). Notarizing needs an Apple Developer account and a
Developer ID certificate added to the workflow.
