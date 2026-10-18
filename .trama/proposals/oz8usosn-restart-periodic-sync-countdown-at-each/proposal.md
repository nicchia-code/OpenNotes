---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: hcc9rci7
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-18T17:00:13.999Z
---
# Restart periodic sync countdown at each run

Risoluzione automatica dei Drift autorizzati:

- D5 – Il ciclo dei 60 secondi non riparte dalla fine dell'ultimo giro: si corregge il codice (opzione 1). Il conto della sincronizzazione periodica viene annullato all'avvio di ogni giro e riparte solo alla sua fine.
