---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: 7panlske
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-12T09:03:29.706Z
---
# Resolve empty block-format note loading

Risoluzione automatica dei Drift autorizzati:

- D3 – Empty block-format note loads its raw JSON as a Title line: correzione nel codice (opzione 1) — un elenco di blocchi valido senza testo si carica come sezione di testo vuota; il ripiego sul testo grezzo resta solo per contenuto che non è un elenco di blocchi valido.
