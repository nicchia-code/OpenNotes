---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: yi11ci28
    decision: fix-code
    option: 1
  - drift: kvrirv6e
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-12T19:48:39.220Z
---
# Resolve startup sync and Google sign-in error Drifts

Risoluzione automatica dei Drift autorizzati, con la prima opzione di correzione per ciascuno.

- D1 – Startup sync after cloud preparation: Model says ignored, code runs it → correzione con l'opzione 1 (mantenere la sincronizzazione all'avvio).
- D2 – Fix code to match the Model: sign-in failures other than the browser → correzione con l'opzione 1 (descrivere nel Model l'errore imprevisto all'avvio dell'accesso Google).
