---
column: done
technical: false
refs:
  - note-editor/Idle/user.PASTE_IMAGE
  - requirements/rules#note-editor
drift: null
proposal: null
agent: false
created: 2026-10-19T16:45:52.122Z
finished: 2026-10-19T16:54:35.889Z
---
# Paste TIFF and BMP clipboard images

When the clipboard holds an image in a format other than PNG, JPEG, GIF or WebP, such as TIFF or BMP, the image is read, converted to PNG, saved as an attachment and inserted into the note, as the Requirement says. Today such an image is not read at all, so the paste fails with the «Immagine non incollata» message.
