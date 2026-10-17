---
status: resolved
resolution: proposal
refs:
  - pending-change/Pending/sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED
  - sync-run/Pushing changes
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: hmikgd4m
created: 2026-10-17T18:19:53.056Z
---
# Account switch leaves a queued delete of an already removed note, which the new account cannot clear

## What happens

Se l'utente elimina definitivamente una nota già sincronizzata con un account, e la cancellazione non è ancora partita (per esempio senza rete), al cambio di account quella cancellazione resta in coda. La nota non è più sul dispositivo, quindi nessuna regola la scarta. Il nuovo account la invia: il cloud la rifiuta, perché la nota appartiene all'altro account. Dopo tre giri la cancellazione viene messa da parte e compare tra le **non sincronizzate** con solo l'identificativo della nota come titolo, mentre l'indicatore segnala che alcune modifiche non si sincronizzano. Né «Riprova» né «Usa la versione del cloud» la chiudono: il primo fallisce di nuovo, il secondo non è offerto perché il nuovo account non vede nessuna copia.

## What should happen

Il Model dice che al cambio di account si scartano senza invio le modifiche delle note rimosse per il cambio di account, e che un cambiamento rifiutato dal cloud per permessi viene contato come rifiutato. Non dice cosa succede alla cancellazione in coda di una nota già eliminata dall'utente prima del cambio: il caso non compare in nessuna uscita dello stato in attesa, e per questo viene inviato e rifiutato. Il Requirement non lo dice.

## Where in the code

lib/core/services/sync_service.dart: _adoptAccount (scarta solo le modifiche delle note ancora presenti sul dispositivo), _pushQueue e _sendQueuedNoteDelete (la cancellazione viene inviata e rifiutata); lib/core/services/database_service.dart: getSetAsideSyncActions e setAsideChanges (il titolo ricade sull'identificativo)
