---
status: resolved
resolution: fix-code
refs:
  - realtime-channel/Listening/supabase.REMOTE_NOTE_DELETED
proposal: null
task: ul2af2nm
origin: null
critical: false
option: 1
note: null
resolvedBy: m16unv7j
created: 2026-10-12T11:20:54.180Z
---
# Unsent saves of a note deleted in the cloud bring it back

## What happens

Quando una nota viene eliminata nel cloud da un altro dispositivo, questo dispositivo la elimina subito. Se però la nota ha ancora un salvataggio in attesa di invio, alla sincronizzazione successiva quel salvataggio viene inviato: la nota ricompare nel cloud e sugli altri dispositivi, come se la cancellazione non fosse mai avvenuta.

## What should happen

Il Modello dice che l'eliminazione dal cloud elimina definitivamente la nota dal dispositivo, e che i cambiamenti in coda vengono inviati sempre, senza essere scartati. Non dice cosa accade quando le due cose si incontrano: seguendo alla lettera le regole della coda, la nota tornerebbe nel cloud subito dopo essere stata cancellata lì. Questo caso va deciso dallo sviluppatore, perché cambia se un'eliminazione fatta altrove prevale sulle modifiche offline.

## Fix options

### Scartare i salvataggi in attesa della nota eliminata

Quando arriva l'eliminazione dal cloud, il dispositivo toglie dalla coda anche i salvataggi ancora in attesa di quella nota. L'eliminazione prevale ovunque e la nota non ritorna. Costo: le modifiche fatte offline su questo dispositivo a una nota eliminata altrove vanno perse senza avviso; il Modello deve aggiungere questa eccezione alla regola che non scarta mai i cambiamenti in coda.

### Inviare comunque i salvataggi in attesa

Le regole della coda restano come sono: il salvataggio in attesa viene inviato e la nota torna nel cloud e negli altri dispositivi, con le modifiche fatte offline. Costo: una nota eliminata di proposito può ricomparire, e per cancellarla davvero bisogna eliminarla di nuovo; nessuna modifica al codice o al Modello.

### Conservare le modifiche come nuova nota

Quando arriva l'eliminazione dal cloud, la nota resta cancellata, ma il suo ultimo salvataggio in attesa viene salvato come nuova nota locale nella cartella Note, senza inviarlo con l'identificativo della nota eliminata. Nessuna modifica va persa. Costo: compare un duplicato da riordinare a mano, e il Modello deve descrivere la creazione di una nuova nota dopo un'eliminazione remota.

## Where in the code

lib/core/services/sync_service.dart: gestione dell'eliminazione remota di una nota e invio della coda; in coda la verifica sul cloud trova la nota assente e invia comunque il salvataggio.
