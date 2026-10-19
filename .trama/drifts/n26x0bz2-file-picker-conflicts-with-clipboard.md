---
status: resolved
resolution: proposal
refs:
  - requirements/tech#General
proposal: null
task: null
origin: 88qqlucx
critical: false
option: null
note: null
resolvedBy: 74z16bne
created: 2026-10-19T16:09:11.069Z
---
# File picker conflicts with clipboard

## What happens

The pinned set cannot be installed: super_clipboard 0.9.1 needs win32 below 6, while file_picker 12.x needs win32 6.3 or more, so pub get fails whatever share_plus version is used.

## What should happen

requirements/tech#General pins super_clipboard 0.9.1 and file_picker 12.2.0, and the Task needs both installed together.

## Where in the code

pubspec.yaml: dependencies file_picker ^12.2.0 and share_plus ^13.3.0 (super_clipboard and image still to be added by Task 88qqlucx)
