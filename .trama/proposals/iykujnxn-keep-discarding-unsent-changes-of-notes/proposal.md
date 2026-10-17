---
status: rejected
base:
  cloud-sync/pending-change.md: e3bac409c906e8ce59c4071b84a8ea6a1c135cfb28b4f585d99757625c43a725
delete: []
created: 2026-10-17T11:38:12.871Z
---
# Keep discarding unsent changes of notes removed by an account change

Perché: la Task yc1qkauv (Proposal 634nfp49) ha tolto dalla macchina pending-change la transizione Queued → Discarded su sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED, mentre sync-run e la nota dicono ancora che il cambio di account scarta i cambiamenti in attesa delle note già sincronizzate. Il codice esegue questo scarto. Senza la transizione, quei cambiamenti non avrebbero un'uscita nel Model.

Decisione sul Drift c5jd98ef, Account change discards unsent changes the Model no longer names in pending-change: proposal. Lo scarto resta: la transizione Pending → Discarded su sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED è dichiarata nella macchina pending-change, con la stessa condizione e lo stesso effetto di oggi (il cambiamento viene tolto dalla coda senza essere inviato e la modifica va persa). Il codice resta com'è.

## Feedback

Drift c5jd98ef resolved by Proposal hp4kwvga
