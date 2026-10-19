---
column: done
technical: false
refs:
  - note-editor/Idle/user.PASTE_IMAGE
  - requirements/rules#note-editor
drift: 8kv3nlf2
proposal: null
agent: false
created: 2026-10-19T16:52:01.834Z
finished: 2026-10-19T17:02:07.695Z
---
# Fix code to match the Model: Menu paste misses clipboard image

## What happens

When the clipboard holds only an image, the text context menu shows no «Incolla» item, so the image cannot be pasted from the menu.

## What should happen

When the clipboard holds only an image, the text context menu shows «Incolla» and pastes the image as an attachment.

## Chosen option

**Show paste when image only**

Show the «Incolla» item in the text context menu when the clipboard holds an image and no text. Tapping it pastes the image the same way as the keyboard paste. When the clipboard holds text, the menu keeps its usual text paste item. The change is limited to the condition that decides when the item appears, so it is small and keeps the current behaviour for text. It does not change the Requirement.

## Where in the code

lib/ui/editor/text_part_context_menu.dart, build, branch that adds the image paste item
