---
status: rejected
base:
  cloud-sync/sync-run.md: 7ad760cc529aabc5dc85cf1e8ce5bd65b10e7187527ffd9f07101dcd137f2d17
  requirements/rules/cloud-sync.md: e957fe64e1e96d37dc77c1cdddc04b2144ab24d955f144598a7b05b164d66f0a
delete: []
created: 2026-10-12T14:17:34.313Z
---
# Discard a queued save of a note deleted before its first sync

Motivo: il Model dice che il salvataggio in coda di una nota mai sincronizzata viene inviato intero anche quando la nota è già stata eliminata sul dispositivo prima della prima sincronizzazione. Il codice invece lo scarta, così il contenuto e gli allegati non partono verso il cloud (sarebbero cancellati subito dopo dall'eliminazione in coda). Il Model e i requisiti non dicono lo scarto in questo caso.

Decisioni:
- Il caso resta uno scarto della coda: nessuna nuova transizione, il cambiamento passa a Discarded con l'evento CHANGE_DISCARDED.
- Si aggiungono il caso alla descrizione dell'evento CHANGE_DISCARDED e alla lista degli scarti senza avviso dei requisiti della coda.

Assunzioni: lo scarto è il comportamento voluto; il codice resta invariato.

## Feedback

Drift eth1srfy resolved by Proposal 3tg049lq
