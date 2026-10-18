---
column: done
technical: false
refs:
  - note-browser
drift: y2i2cnqg
proposal: null
agent: false
created: 2026-10-18T20:03:12.589Z
finished: 2026-10-18T20:07:52.304Z
---
# Fix code to match the Model: Hashtags in hidden protected notes appear in the tag list

## What happens

The tag list and tag counts include #tags written in the text of a protected note that is still locked for the session, so the tag shows up in the sidebar and in note labels while its content stays hidden. Selecting such a tag finds no notes, because the tag filter only matches saved tags.

## What should happen

The note-access Model keeps the content of a locked note hidden and lists only its title, date, tags and lock icon. The note-browser Requirements count hashtags written in the content for the tag list, and the search rule already leaves the hidden text of a locked note out of the search.

## Chosen option

**Leave hidden text out of the list**

For a protected note still locked for the session, count and list only its saved tags, the same rule the search uses. Tags appear again after unlocking.

## Where in the code

lib/core/services/database_service.dart getAllTags (tag list counts) and getNotes (tag filter matching); lib/core/models/note_model.dart extractTagsFromContent
