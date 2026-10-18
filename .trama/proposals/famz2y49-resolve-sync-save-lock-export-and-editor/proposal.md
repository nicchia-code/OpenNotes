---
status: approved
kind: resolution
drifts:
  - drift: np95d1j4
    decision: proposal
  - drift: z1x62aeh
    decision: proposal
  - drift: mpmho76c
    decision: proposal
  - drift: i37jfj7f
    decision: proposal
  - drift: hos9wvlz
    decision: proposal
  - drift: 686ya8s6
    decision: proposal
  - drift: myzdecuv
    decision: proposal
  - drift: brglgjm5
    decision: proposal
  - drift: fmffyhf1
    decision: proposal
  - drift: ky1rufpg
    decision: proposal
  - drift: k55jcly1
    decision: proposal
  - drift: vhczaywa
    decision: proposal
  - drift: gcck19f2
    decision: proposal
  - drift: 9dhiuw7k
    decision: proposal
  - drift: nou8w4aw
    decision: proposal
  - drift: e0c6nq2n
    decision: proposal
  - drift: y8iuj9nq
    decision: fix-code
    option: 1
base:
  export/export-markdown-file.md: 24f20fb9639976bff201b85c6c56de40e3cb4a2930bbbed14dbf015df4453559
  actors/operating-system.md: 74983271cf6326a7421eaac2dfecfe756d99f1351e7defca6cea999e8ef95ff1
  cloud-sync/sync-run.md: 8ae563a721989811e198eed1651299e37aa3264dc1e24a24484abd87a507db51
  cloud-sync/account.md: bc99c21e2e46a1c86846c88e6d8e7756dc22817668d37d9c88a37df65d3f363f
  editor/note-content-save.md: bd2eec7ccd158d1cbae4a0e32fd676ac5c8497bedc9de92b2b3390cf505afa85
  editor/note-editor.md: bcc6b114c2fcb6dd2c0d11ad3a917eda431b1c238a17a175ff1a4c43bae9772a
  cloud-sync/pending-change.md: 0b037827275126c1084be1f3ab7870bb589e24be68b6e9f170fb26d03f8eeb5f
  organization/folder.md: d9b00a350f84b821e14b49ca53097b6643ce0ca525b63b0a4b5c0f5103c2e6cc
  notes/note.md: 6d7b119c5dea316f3d413b0300b27a955672d0c61c1b515e8ab8f88ccaf760ab
  navigation/mobile-navigation.md: 73a32c2ed990178cb8616856b0f13550adf5c4bd7828f8e1689159ca93be89fc
  note-lock/note-access.md: d9e94b25b738b1695cf9702c990e54c047fc38d844d176a9fb5b10afe6a1585c
  editor/text-line.md: e2ba725c43b185892a698759069a2f84fbc96a69a6c4170f72b56a0a315f3e96
  editor/editor-suggestions.md: 4f58d958731280e02040dea58ec6185a314be4663403e0c22c35faef0f795231
  requirements/rules/export.md: 5dea93834f825db6c57c58dcf1fb2d2a237526fe41c9654d87621d842fabe40b
  requirements/rules/sync-run.md: 602c85a04e42ca7bb5140271a7141a11c9b92e964daec42a47adef20c6c0c314
  requirements/rules/editor.md: 02ed0eb007f1c12eeb436779988871640704e81e919c2ac10a274166f4bdfedb
  requirements/rules/cloud-sync.md: 00bf74c7c0019eb4561f115409e48cc9fcbf670ca2abbe8409d691f3f83405fa
  requirements/rules/organization.md: f7b680aeec3084afa328bbd788f4f7e3e558a3064370c06e691f32f8c63818c9
  requirements/rules/notes.md: 9c6a7cbac7d77b63dfc7b65c07d1537b01e53cd3344685ef34fdbe4ab9b04a25
  requirements/data/organization.md: 01593d3c99f1f6be92ed159aea728021369f25a6712b0d664cd5da1aed432307
  requirements/data/note-lock.md: b262e2149317fe634751d2c60806946b4aa5d03f68e3d507bb78120ab2751f3d
  requirements/data/export.md: 5aed8b709fe77488b1b2d62a4f0bcefd1c044bdf6ee2296e41cc0095c6fe0660
  requirements/tech/general.md: 7955a426aa2d6a93d9ffda6416df4cb885122fc53438433a3bf1f7e585bea0d4
  requirements/rules/note-lock.md: 1a293921233c09988b515d26dc58fe112df3fdd94ad48806821ee8d9c0605093
delete: []
created: 2026-10-18T19:29:36.836Z
---
# Resolve sync, save, lock, export and editor Drifts

Resolution of 17 Drifts, from the developer's answers.

- np95d1j4 Failed Markdown file write has no outcome in the Model: the Model and the export rule describe the error message, no file and unchanged note (proposal).
- z1x62aeh Offline sign-in remembers a full check the Model does not describe: an offline sign-in starts no run and remembers a full check for the network's return, like the initial session (proposal).
- mpmho76c Waiting save of another note is written at once: the Model says the other note's waiting version is written at once, not replaced (proposal).
- i37jfj7f Cloud lock hides the note: when a protected cloud version is applied, the editor hands over its pending text and the waiting save is written at once (proposal).
- hos9wvlz Set-aside changes are discarded by pulls and account switches: set-aside changes fall to the same discards as any queued change; the missing discard exits are added (proposal).
- 686ya8s6 Pending change has no exit to Sent: Queued is the one waiting state, Pending only groups the exits shared with Set aside, with replacement and discard exits (proposal).
- myzdecuv Search rule still counts protected note text: for a protected note still locked in the session the search uses only title and tags (proposal).
- y8iuj9nq Shared text drops the part of a long first line: the shared body keeps the whole first line, the code is to be fixed (fix-code, option 1).
- brglgjm5 Drawing and photo on a locked protected note: the keyboard-bar tools stay active and edit the hidden document; the mobile navigation Model says so (proposal).
- fmffyhf1 Requirement says the vault sets the lock on reading: the vault is write-only; the reading is removed from the Requirements (proposal).
- ky1rufpg Permanent delete of an unlocked protected note skips the PIN: the PIN is asked only for a protected note not yet unlocked in the session (proposal).
- k55jcly1 Note rapide still named in the folder Model: the view is removed from the Model and the Requirements (proposal).
- vhczaywa Folder the cloud no longer has ignores a newer queued change: the cloud always wins; the folder is removed and its queued changes discarded (proposal).
- gcck19f2 Queued save of a welcome note removed without sending: the queued save is dropped and the sync decides the note's fate (proposal).
- 9dhiuw7k Tag after square or curly bracket is accepted: the tag rule also allows square and curly brackets (proposal).
- nou8w4aw Lines with a number, quote or fence sign load as body text: they load as body with the sign in the text and take their type at the first edit (proposal).
- e0c6nq2n Menus follow Tab, Enter and Backspace edits: the suggestions Model follows those keys like typing, also when the menus are hidden (proposal).
