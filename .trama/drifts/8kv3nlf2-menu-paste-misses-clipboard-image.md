---
status: resolved
resolution: fix-code
refs:
  - note-editor/Idle/user.PASTE_IMAGE
  - requirements/rules#note-editor
proposal: null
task: m9s3ls7n
origin: null
critical: false
option: 1
note: null
resolvedBy: 0gt0qtek
created: 2026-10-19T16:45:52.151Z
---
# Menu paste misses clipboard image

## What happens

When the clipboard holds only an image, the text context menu shows no «Incolla» item, so the image cannot be pasted from the menu.

## What should happen

When the clipboard holds only an image, the text context menu shows «Incolla» and pastes the image as an attachment.

## Fix options

### Show paste when image only

Show the «Incolla» item in the text context menu when the clipboard holds an image and no text. Tapping it pastes the image the same way as the keyboard paste. When the clipboard holds text, the menu keeps its usual text paste item. The change is limited to the condition that decides when the item appears, so it is small and keeps the current behaviour for text. It does not change the Requirement.

### Always show paste in menu

Show the «Incolla» item in the text context menu every time, without checking the clipboard first. When the item is tapped, the clipboard is read: text is pasted as text, an image is pasted as an attachment, and nothing happens when the clipboard holds neither. This keeps the menu logic simple and always in line with what the clipboard holds at tap time, but the item can do nothing when the clipboard is empty.

## Where in the code

lib/ui/editor/text_part_context_menu.dart, build, branch that adds the image paste item
