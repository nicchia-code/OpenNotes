---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: o4es5ttq
    decision: fix-code
    option: 1
  - drift: 9nij8tfz
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-18T17:51:23.199Z
---
# Fix unlocked-note permanent delete PIN and slash command removal

Risoluzione automatica dei Drift autorizzati, con la prima opzione di correzione:
- o4es5ttq Permanent delete asks the PIN again for an already unlocked note: si corregge il codice, l'eliminazione definitiva non chiede più il PIN per una nota già sbloccata in questa sessione.
- 9nij8tfz Slash command removal stops at combining marks of other alphabets: si corregge il codice, la rimozione del comando del menu rapido toglie anche i segni combinanti, come il riconoscimento dei tag.
