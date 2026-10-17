---
status: rejected
base:
  cloud-sync/pending-change.md: 8bd947202ac527a3a4922e48286d184f87308ada74d9aad99fca9d5a5aff2193
  cloud-sync/sync-run.md: 5ab9c764f177fa5e14df30b382df8902a8776a06b0f8754500148619818808bd
delete: []
created: 2026-10-17T18:17:10.719Z
label: "Cambio account: cancellazioni"
---
# Discard queued deletes of notes already removed when the account changes

Un'eliminazione definitiva accodata per una nota già sincronizzata dal precedente account resta in coda quando cambia l'account: la nota non è più sul dispositivo e il Model non dice cosa ne sia di quella cancellazione. Il nuovo account la invia, il cloud la rifiuta perché la riga appartiene all'altro account, e la voce finisce tra le non sincronizzate senza modo di toglierla.

Decisioni prese senza intervista (da verificare):
- Al cambio di account, la cancellazione in coda di una nota già sincronizzata dal precedente account viene scartata senza essere inviata, anche se la nota è già stata eliminata definitivamente sul dispositivo: come le altre modifiche delle note del precedente account.
- L'evento del cambio di account, per queste cancellazioni, è lo stesso già previsto per le note rimosse dal dispositivo.
- Nessuna nuova uscita per il cloud: un rifiuto per permessi resta un rifiuto.

## Feedback

Drift sjc4b5p9 resolved by Proposal hmikgd4m
