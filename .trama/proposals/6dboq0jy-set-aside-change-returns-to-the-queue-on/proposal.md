---
status: rejected
base:
  cloud-sync/pending-change.md: e3bac409c906e8ce59c4071b84a8ea6a1c135cfb28b4f585d99757625c43a725
delete: []
created: 2026-10-17T14:11:59.542Z
---
# Set-aside change returns to the queue on save or permanent delete

Il Requirement delle regole di pending-change dice che un nuovo salvataggio, e anche un'eliminazione definitiva, di una nota messa da parte la rimette in coda al suo posto, senza più essere messa da parte: il codice e il test lo fanno. Il Model non lo dice: lo stato Set aside ha solo le uscite dell'utente. Questa Proposal aggiunge la transizione al Model.
- Decisione: un salvataggio o un'eliminazione definitiva di una nota messa da parte porta il cambiamento di nuovo in coda, con il conteggio dei rifiuti azzerato e l'emissione di QUEUED; la base di revisione resta quella di prima.
- Nessuna modifica ai Requirement: già dicono così.

## Already present
- `pending-change/Set aside/note.SAVED`
- `pending-change/Set aside/note.PERMANENTLY_DELETED`

## Feedback

Drift hs8vzsqq resolved by Proposal awa4vyj9
