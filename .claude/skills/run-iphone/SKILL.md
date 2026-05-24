---
name: run-iphone
description: Build, install, and launch the Recall app on a connected physical iPhone. Use when the user asks to run, test, or deploy the app on their phone or a real device (as opposed to the iOS Simulator).
---

# Run on physical iPhone

Builds the Recall app, installs it on the connected physical iPhone, and launches it.

## Project facts

- Xcode project: `Recall/Recall.xcodeproj`
- Scheme: `Recall`
- Bundle identifier: `com.recall.app`
- Built `.app` path (relative to `Recall/`): `build-device/Build/Products/Debug-iphoneos/Recall.app`

## Steps

### 1. Find the connected device

Use `xcrun xctrace list devices` (not `xcrun devicectl list devices`) to get the UDID in the
legacy format that xcodebuild accepts:

```
xcrun xctrace list devices
```

Pick the physical iPhone row (not a Simulator). Take its UDID, e.g. `00008101-001D2D820A21001E`.
If none is connected, tell the user to plug in and unlock their iPhone, then stop. If more than
one physical device is connected, ask the user which to use.

> **Why not `devicectl`?** `devicectl list devices` returns CoreDevice-format identifiers that
> xcodebuild does not recognise. Always use `xctrace list devices` for the UDID.

### 2. Build for the device

Run from the `Recall/` subdirectory (not the repo root — the `.xcodeproj` lives there):

```
xcodebuild build -scheme Recall -configuration Debug \
  -destination 'id=<UDID>' \
  -allowProvisioningUpdates \
  -derivedDataPath ./build-device
```

`-allowProvisioningUpdates` lets Xcode handle code signing automatically. Confirm the output
ends with `** BUILD SUCCEEDED **`. If signing fails, the user must open the project in Xcode
once to register the device / development team.

### 3. Install on the device

```
xcrun devicectl device install app --device <UDID> \
  ./build-device/Build/Products/Debug-iphoneos/Recall.app
```

### 4. Launch the app

```
xcrun devicectl device process launch --device <UDID> --terminate-existing com.recall.app
```

`--terminate-existing` kills any running instance first so the new build starts cleanly.

## Capturing device logs (optional)

The app logs via `os.Logger` under subsystem `com.recall.app` (categories: `database`,
`repository`, `ui`). To stream them from the device while reproducing a bug:

```
idevicesyslog -u <UDID> -p Recall
```

Run it in the background, have the user reproduce the issue, then read the output. If
`idevicesyslog` reports "Waiting for device... to become available", it cannot reach the
device over usbmux — fall back to **Console.app** (select the iPhone in the sidebar, filter
by subsystem `com.recall.app`).

## Notes

- The `Recall/build-device/` directory holds build artifacts; it can be deleted freely and
  should not be committed.
- This deploys a Debug build. For a Release build, change `-configuration` and the
  `Debug-iphoneos` path segment to `Release-iphoneos`.
