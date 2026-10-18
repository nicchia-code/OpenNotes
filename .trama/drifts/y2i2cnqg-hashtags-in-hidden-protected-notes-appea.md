---
status: resolved
resolution: fix-code
refs:
  - note-browser
proposal: null
task: ebszebsy
origin: null
critical: false
option: 1
note: null
resolvedBy: 2ckxa2av
created: 2026-10-18T19:48:16.450Z
---
# Hashtags in hidden protected notes appear in the tag list

## What happens

The tag list and tag counts include #tags written in the text of a protected note that is still locked for the session, so the tag shows up in the sidebar and in note labels while its content stays hidden. Selecting such a tag finds no notes, because the tag filter only matches saved tags.

## What should happen

The note-access Model keeps the content of a locked note hidden and lists only its title, date, tags and lock icon. The note-browser Requirements count hashtags written in the content for the tag list, and the search rule already leaves the hidden text of a locked note out of the search.

## Fix options

### Leave hidden text out of the list

For a protected note still locked for the session, count and list only its saved tags, the same rule the search uses. Tags appear again after unlocking.

### Keep the current behaviour

Keep counting hashtags of locked notes in the list and counts, and document that the list reveals them.

### Show tags of locked notes only after unlock

Hide the content-derived tags of locked notes until the session unlock, and keep their saved tags visible as the note-access Model says.

## Where in the code

lib/core/services/database_service.dart getAllTags (tag list counts) and getNotes (tag filter matching); lib/core/models/note_model.dart extractTagsFromContent
