---
status: resolved
resolution: fix-code
refs:
  - pending-change/Queued
proposal: null
task: 6erq4xog
origin: null
critical: false
option: 1
note: null
resolvedBy: m16unv7j
created: 2026-10-12T11:21:32.120Z
---
# Queued edit of a note deleted in the cloud brings the note back

## What happens

Se una nota è stata eliminata nel cloud, per esempio da un altro dispositivo, mentre questo dispositivo ha ancora una modifica in coda per la stessa nota, alla sincronizzazione la modifica viene inviata e la nota ricompare nel cloud, e da lì sugli altri dispositivi. Il dispositivo non controlla se la nota esiste ancora nel cloud: una nota assente non ferma la modifica.

## What should happen

Il Model della nota dice che, quando la nota viene eliminata nel cloud, viene rimossa dal dispositivo **senza accodare nulla**, ma non dice che cosa succede alle **modifiche ancora in coda** per quella nota. Il Requirement sulle regole di sincronizzazione non copre una nota che il cloud non ha più. Serve una scelta esplicita: se vince la cancellazione o se la modifica riporta la nota.

## Fix options

### Deletion wins, the pending edit is dropped

La modifica in coda di una nota che il cloud non ha più viene tolta senza essere inviata, e la nota resta eliminata su tutti i dispositivi. È coerente con la rimozione senza accodare già prevista per le note eliminate nel cloud. Costo: una modifica fatta offline prima della cancellazione altrove si perde, e va scritto nel Model e nel Requirement.

### The pending edit brings the note back

La modifica in coda riporta la nota nel cloud, come oggi: nessun testo scritto offline si perde. Costo: una nota eliminata da un altro dispositivo torna su tutti i dispositivi, anche dove era stata cancellata di proposito, e il Model deve dire che la modifica vince sulla cancellazione.

### Keep the pending edit as a new note

La modifica in coda diventa una nuova nota con un nuovo identificativo, così la cancellazione resta e il testo scritto offline viene salvato. Nessun dato si perde, ma compare una nota in più che l'utente deve riconoscere e rimuovere. Costo: serve codice per cambiare identificativo e per collegare la nuova nota al suo file nel vault.

## Where in the code

lib/core/services/sync_service.dart: syncNow, passo 1 della coda, ramo delle note (con la nota assente nel cloud l'invio avviene senza confronto)
