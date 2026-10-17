---
status: approved
kind: resolution
drifts:
  - drift: ydm5fxwe
    decision: fix-code
    option: 1
  - drift: tjeoc6wb
    decision: proposal
  - drift: e61p0nur
    decision: proposal
  - drift: p5vceocl
    decision: proposal
  - drift: jkugm6i1
    decision: fix-code
    option: 1
  - drift: uixcjl5n
    decision: proposal
base:
  note-lock/note-access.md: dbdd30b717f62a78587491e1143f2d0e8cd17e7f905efedec18f6b9d3194d46b
  notes/note.md: f5abea93eeb74649a3ff68771e7e9d2dbc3efcc7e89c1510ff35552fcb5346cd
  organization/folder.md: 8afc8c09ff28bc2eadfd122c5ca79e3df934a6ccd3721949d0af0168c837069d
  requirements/rules/note-lock.md: 7864c275093aae1dd9e38c5ecb9f95dbed5c2300800d9e834a4cf0e477d11f13
delete: []
created: 2026-10-17T11:38:21.751Z
---
# Resolve six Drifts on note lock, trash, vault, folder picker and note switch

Risolve sei Drift secondo le decisioni dello sviluppatore:
- ydm5fxwe – Search still matches the hidden text of protected notes: fix-code, opzione 1 (la ricerca usa solo titolo e tag finché la nota è bloccata).
- tjeoc6wb – Model still has no exits for a lock that arrives with a remote version: proposal, il lucchetto segue il cloud e il Model dell'accesso riceve le uscite per la versione remota.
- e61p0nur – Model still says the empty-trash PIN check covers only shown notes after the fix: proposal, «nel cestino» nel Model dell'accesso, nel Model delle note e nel Requirement.
- p5vceocl – Model still says protected notes arrive from the vault after the fix: proposal, tolto «o dal vault» dallo stato Unprotected.
- jkugm6i1 – Note switch saves the waiting edit to the previous note, the Model says it is discarded: fix-code, opzione 1 (la modifica in attesa viene scartata al cambio di nota).
- uixcjl5n – Folder picker shows subfolders as a tree, the Model says all folders share one level: proposal, il Model della cartella descrive l'albero del selettore «Sposta in…».
