---
status: resolved
resolution: proposal
refs:
  - pending-change/Pending
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T17:35:48.996Z
---
# Pending change has no exit to Sent, and Queued lacks the replacement and discard exits

## What happens

Ogni modifica entra in coda e viene inviata alla sincronizzazione successiva, ma nel Model lo stato Pending non ha alcuna uscita verso Sent: le sue uniche transizioni sono le scariche e note.SAVED verso Queued. Lo stato Queued non ha transizioni per un nuovo salvataggio o eliminazione che sostituisce la modifica in coda, né per le scariche (copia del cloud più recente, nota rimossa, cambio di account), che il codice applica anche a elementi in coda normali.

## What should happen

Il Model dice che Pending e Queued sono entrambi iniziali, ma non dice quale dei due descriva una modifica appena accodata. Il Requirement dice che un nuovo salvataggio sostituisce l'elemento esistente nella stessa posizione con rifiuti azzerati, e che ogni accodamento chiede una sincronizzazione: in codice non c'è distinzione fra Pending e Queued, e la sostituzione avviene su un solo elemento per nota. Il Model non descrive questo percorso.

## Fix options

### Make Queued the only working state in the Model

Nel Model far entrare ogni modifica direttamente in Queued, ed eliminare Pending oppure lasciarlo solo come stato di ingresso senza uscite proprie. Aggiungere a Queued le transizioni per nuovo salvataggio o eliminazione che sostituisce, e per le scariche applicate oggi alla coda. Il codice non cambia.

### Model Pending as the state of a queued change, with its own exits

Tenere Pending come stato di una modifica in coda con l'elemento sul dispositivo, e aggiungere la transizione da Pending a Sent (o a Queued) quando una sincronizzazione la invia. Queued diventa lo stato dopo un rifiuto o una sostituzione. Il codice non cambia, ma il Model va riscritto in modo che ogni stato abbia un'uscita verificabile.

## Where in the code

lib/core/services/database_service.dart: queueSyncAction, removeSyncActionIfUnchanged, recordRejectedSyncAction; lib/core/services/sync_service.dart: _pushQueue, _sendQueuedNote, notifyNoteChanged
