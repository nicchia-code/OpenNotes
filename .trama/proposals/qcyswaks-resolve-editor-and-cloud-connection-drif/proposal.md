---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: cx2vtvo1
    decision: fix-code
    option: 1
  - drift: e79wmv5n
    decision: fix-code
    option: 1
  - drift: t9jho5wg
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-12T17:41:07.573Z
---
# Resolve editor and cloud connection drifts

Risoluzione automatica dei Drift autorizzati per questa raccolta, ciascuno con la prima opzione di correzione:
- Build defaults would stop being saved, but the Model still requires saving them: correzione nel codice, opzione 1 (aggiornare prima Model e Requirement del collegamento cloud, poi il codice).
- Mobile editor closes when its note leaves the list, the Model says it stays open: correzione nel codice, opzione 1 (chiudere l'editor mobile quando la nota esce dall'elenco).
- Remote reload forgets the active part: correzione nel codice, opzione 1 (tenere la parte attiva per posizione dopo il ricaricamento remoto).
