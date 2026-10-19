---
created: 2026-10-19T16:46:15.193Z
updated: 2026-10-19T18:03:56.296Z
summary: Added Ctrl/Cmd+V and context-menu paste of clipboard images into note text parts, placed at the cursor (the text is split around the image), including TIFF and BMP clipboard images converted to PNG, and Paste shown for image-only clipboards.
tasks:
  - 88qqlucx
  - xuumrxyj
  - h7d2w7yr
  - sax9tecd
  - m9s3ls7n
  - symhphii
---
# Clipboard image paste in the note editor

Implemented six Tasks: clipboard libraries (super_clipboard, image, share_plus 12.0.2, file_picker 11.0.3), clipboard image reader, image paste into the note editor (Ctrl/Cmd+V only when the clipboard has no text, a Paste entry in the text context menu, a SnackBar 'Immagine non incollata' on failure), TIFF and BMP clipboard reading with conversion to PNG (Task sax9tecd), the context-menu Paste for image-only clipboards (Task m9s3ls7n, fixing Drift 8kv3nlf2), and insertion at the cursor (Task symhphii): the image goes where the caret is, the text is split around it, a selection is removed, list markers continue, and the caret moves below the image. Known gaps: the clipboard reader and paste path, including TIFF and BMP, were not exercised on a device; only unit and widget tests cover them, and the editor-level paste flow has no automated test because the keyboard path reads the real clipboard. Verification: flutter analyze --no-fatal-infos exits 0 on the whole project (83 info-level issues, none fatal, one of them an unnecessary import in text_part_split.dart); flutter test all passed; flutter build macos --debug succeeded.
