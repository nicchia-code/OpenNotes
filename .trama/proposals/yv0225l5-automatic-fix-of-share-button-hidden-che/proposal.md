---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: pvup8bjv
    decision: fix-code
    option: 1
  - drift: n2vqm9up
    decision: fix-code
    option: 1
  - drift: de7yfjjn
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-12T12:11:53.064Z
---
# Automatic fix of share button, hidden checklist item and permanent deletion order

Risoluzione automatica: ogni Drift viene corretto nel codice con la prima opzione di correzione.

- D4 – Mobile editor shares trashed notes, the Model leaves the trash out: correggere il codice (opzione 1), il pulsante di condivisione dell'editor mobile non compare per le note nel cestino.
- D9 – Checklist command on a hidden note adds the item after the active part, not at the end: correggere il codice (opzione 1), la voce vuota va in fondo al documento nascosto.
- D13 – Permanent deletion removes the file last, while the Requirement puts the file first: correggere il codice (opzione 1), l'eliminazione definitiva segue l'ordine scritto: prima il file, poi la cancellazione in coda per il cloud, infine la nota dal database.
