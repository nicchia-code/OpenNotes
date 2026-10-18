---
column: done
technical: false
refs:
  - export-markdown-file/Choosing destination
  - requirements/rules#export
drift: null
proposal: null
agent: false
created: 2026-10-18T19:45:34.126Z
finished: 2026-10-18T19:50:29.118Z
---
# Fix code to match the Requirements: Empty title line in another block exports as a blank line, not as a heading

Markdown conversion of a note (NoteModel.toMarkdown, lib/core/models/note_model.dart) turns a line with lineStyle title that is empty into an empty line, while the Requirement says a title/h1 line becomes '# ' (only the block title is an empty line when empty). Change the title branch so an empty title line gets '# ' like h1 does, while block titles keep their empty-line rule. Acceptance: exported Markdown of a paragraph whose first line is styled title and empty has the line '# '; block title empty stays empty.
