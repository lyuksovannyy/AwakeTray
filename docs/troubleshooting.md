# Troubleshooting

## The eye does not appear in the menu bar

On a MacBook with a notch, macOS adds new menu bar icons at the left end of the row. If the menu
bar is already full, the new icon lands behind the notch and is invisible, even though AwakeTray
is running.

Make room for it:

- Hold Cmd and drag an icon you do not need off the menu bar, or quit an app with a wide menu
  bar item. The eye slides out from behind the notch.
- Or tighten the spacing between all menu bar icons, then log out and back in:

  ```sh
  defaults -currentHost write -globalDomain NSStatusItemSpacing -int 8
  defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 6
  ```

  To undo, delete both values with `defaults -currentHost delete -globalDomain <name>`.

Once the eye is visible you can Cmd-drag it to wherever you want it; macOS remembers the spot.

## macOS refuses to open the downloaded app

Release builds are not notarized by Apple, so macOS blocks them the first time. Either:

- try to open the app once, then go to System Settings > Privacy & Security and choose
  **Open Anyway**, or
- remove the download flag in Terminal:

  ```sh
  xattr -dr com.apple.quarantine /Applications/AwakeTray.app
  ```

## The Mac still went to sleep

- Closing the lid always sleeps the Mac; AwakeTray only blocks idle sleep.
- A timed session may have ended. The eye closes when it does.
- Check what is active with `pmset -g assertions`. While AwakeTray is on, the list contains
  "AwakeTray is keeping this Mac awake".

## The screen turns off while AwakeTray is on

Turn on **Keep the display on too** in the settings. With it off, only the Mac itself is kept
awake and the display follows its normal timer.

## Reset the settings

```sh
defaults delete com.lyuksovannyy.AwakeTray
```

Quit AwakeTray first, then start it again.
