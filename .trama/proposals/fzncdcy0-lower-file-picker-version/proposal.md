---
status: rejected
base:
  requirements/tech/general.md: f1ea63bc89737c08dd9f8f76af4176ce60e99169b00fb01682e42de2c56926ad
delete: []
created: 2026-10-19T16:08:56.454Z
---
# Lower file_picker version

Why: requirements/tech#General pins super_clipboard 0.9.1 and file_picker 12.2.0, which cannot be installed together. super_clipboard 0.9.1 needs win32 below 6 (through super_native_extensions and device_info_plus below 12); every file_picker 12.x needs win32 6.3 or more (through windows_file_picker). The pins of share_plus 12.0.2 (approved with the share_plus Drift) are compatible with super_clipboard.

Decisions:
- super_clipboard 0.9.1 and share_plus 12.0.2 stay as they are.
- file_picker is pinned to 11.0.3, the newest 11.x version that resolves with the other two; checked with pub get.
- The code that calls file_picker may need changes for the 11.x API; that is a separate Task, written when the developer decides.

## Feedback

Drift n26x0bz2 resolved by Proposal 74z16bne
