---
status: approved
kind: resolution
drifts:
  - drift: qk34x0q1
    decision: proposal
  - drift: pvvfoloi
    decision: proposal
  - drift: o5cdlfm3
    decision: proposal
  - drift: 7myd7fu9
    decision: proposal
base:
  organization/note-browser.md: 56d2a51ef83331a8ca75a2f3ae8e96400746f88ca3eb250590dbed3ed2d20166
  system.md: ca09f3782daf63b0ccc0b5d94602650729ad1fa3b4fefe66dac70c717e890e79
  actors/user.md: 0bdb3baa66b819f873b7da3ebee44f760fe155412e7081e0a33dffe988bb7208
  actors/operating-system.md: 2885fdfcef0d1869e3d7bd6bb1c04e6b248e96d47a8f1b961e132b9ed2241c23
  export/feature.md: 82101b192e31ea61182be2063d7bdbb7751ac2f700548242767cff97e92aa6fa
  requirements/rules/export.md: 0c6c98b12debcb09ca3335f46ff9a60bec7d50fe990b89072dbdde86b549fb05
  requirements/rules/editor-text.md: 13cfddd9e7be61fc6d2eb37692b0da119f3b85cd142750c4024b11b55003f168
  requirements/tech/general.md: 34acf6e41f0d99bb02ca7d443af0ddf0249fa16f8517b319b34c16ccf7f02cf7
  export/export-pdf.md: d983763dd09addf8ce2def4b71d1226cf2803d398c215a2406fd09d597218992
delete:
  - export/export-pdf.md
created: 2026-10-18T21:22:16.275Z
---
# Drop PDF, align lock refresh

Resolves four Drifts by making the Model and Requirements describe what the code does.

- qk34x0q1 – PDF body repeats a clipped title again: proposal. The app no longer has a PDF export (service and packages removed), so the PDF export Machine, its Events and Requirement are removed.
- pvvfoloi – Slash removal also takes underscores and hyphens: proposal. Choosing a quick-menu entry removes the slash and the following tag characters, including underscore and hyphen, as for tags.
- o5cdlfm3 – Tag list refresh: lock and unlock are not in the Model: proposal. The tag list refreshes when a note is locked or its lock removed, and when a protected note is unlocked for the session or hidden again.
- 7myd7fu9 – Note list reload on unlock and relock is not in the Model: proposal. Unlocking and relocking a protected note reload the note list and emit LIST_RELOADED.
