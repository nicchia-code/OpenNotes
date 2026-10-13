---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: mhdhstxk
    decision: fix-code
    option: 1
  - drift: qe5hjjfy
    decision: fix-code
    option: 1
  - drift: nh24mh69
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-13T12:30:18.712Z
---
# Resolve tag ordering, state change saves and remote folder deletion drifts

Risoluzione automatica dei Drift autorizzati, tutti corretti nel codice con la prima opzione:

- D1 – Tags are not sorted alphabetically when they contain accented letters: correggere il codice, ordinando i tag con un confronto alfabetico sensibile agli accenti.
- D7 – Pin, trash, restore and move can save an older text over a newer one still being written: correggere il codice, consegnando e scrivendo il testo in attesa prima di ogni cambio di stato.
- D8 – Remote folder deletion moves the open folder view to All notes: correggere il codice, mantenendo la vista sulla cartella eliminata dal cloud.
