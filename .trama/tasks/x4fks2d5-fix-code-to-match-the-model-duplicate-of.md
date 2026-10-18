---
column: done
technical: false
refs:
  - note/Not yet created/user.DUPLICATE_NOTE
  - requirements/rules#note
drift: null
proposal: null
agent: false
created: 2026-10-18T19:47:30.500Z
finished: 2026-10-18T19:51:04.671Z
---
# Fix code to match the Model: Duplicate of a note lands in Notes when another folder view is gone

Duplicating a note puts the copy in the folder of the original note, as the Model says (same folder). The code sets the copy's folder to Notes whenever the open folder view has disappeared, even when the original note still sits in an existing folder. The copy must keep the original note's folder; the Notes fallback applies only when that folder itself no longer exists.
