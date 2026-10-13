---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: kf428sgu
    decision: fix-code
    option: 1
  - drift: ns3fdb2e
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-13T12:49:52.137Z
---
# Resolve sync removal notification and trash save Drifts

Risoluzione automatica dei Drift autorizzati per questa raccolta, scegliendo per ciascuno la prima opzione di correzione:
- Notes removed by a sync run are not reported to the lists until the run ends: fix-code, opzione 1 (emettere CloudNoteRemoved per ogni nota eliminata dalla sincronizzazione).
- Model still says the editor discards the waiting edit when the note is trashed, but trash saves it first: fix-code, opzione 1 (consegnare la modifica prima del cestino e correggere il Model).
