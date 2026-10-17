---
status: resolved
resolution: proposal
refs:
  - requirements/docs#General
proposal: null
task: null
origin: brgmc482
critical: false
option: null
note: null
resolvedBy: 1mjjves7
created: 2026-10-17T09:40:00.937Z
---
# Dark theme screenshot cannot be produced on Linux

## What happens

Launching the Linux release bundle with an isolated HOME always renders the light theme: the app uses ThemeMode.system, GTK reports Adwaita-dark, but Flutter does not switch brightness (no portal call, no theme change in capture).

## What should happen

Provide a documented, repeatable way to launch the app in dark mode for the dark screenshot, without altering app code or using the developer's account.

## Fix options

### Document a supported way to force dark mode for Linux capture (e.g. a launch flag or setting the app's theme preference).

Add an explicit theme override in the app or a dev flag used only for capture.

### Capture the dark screenshot on macOS or Windows where system dark mode is controllable.

Take the dark PNG on another platform and keep the Linux light one.

## Where in the code

lib/main.dart (ThemeMode.system at line 290); the Linux bundle built from it
