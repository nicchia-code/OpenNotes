---
column: done
technical: false
refs:
  - realtime-channel/Listening/supabase.REMOTE_NOTE_DELETED
drift: nl2xott5
proposal: null
agent: false
created: 2026-10-12T11:27:34.831Z
finished: 2026-10-12T11:28:56.532Z
---
# Fix code to match the Model: Unsent saves of a note deleted in the cloud bring it back

## What happens

Quando una nota viene eliminata nel cloud da un altro dispositivo, questo dispositivo la elimina subito. Se però la nota ha ancora un salvataggio in attesa di invio, alla sincronizzazione successiva quel salvataggio viene inviato: la nota ricompare nel cloud e sugli altri dispositivi, come se la cancellazione non fosse mai avvenuta.

## What should happen

Il Modello dice che l'eliminazione dal cloud elimina definitivamente la nota dal dispositivo, e che i cambiamenti in coda vengono inviati sempre, senza essere scartati. Non dice cosa accade quando le due cose si incontrano: seguendo alla lettera le regole della coda, la nota tornerebbe nel cloud subito dopo essere stata cancellata lì. Questo caso va deciso dallo sviluppatore, perché cambia se un'eliminazione fatta altrove prevale sulle modifiche offline.

## Chosen option

**Scartare i salvataggi in attesa della nota eliminata**

Quando arriva l'eliminazione dal cloud, il dispositivo toglie dalla coda anche i salvataggi ancora in attesa di quella nota. L'eliminazione prevale ovunque e la nota non ritorna. Costo: le modifiche fatte offline su questo dispositivo a una nota eliminata altrove vanno perse senza avviso; il Modello deve aggiungere questa eccezione alla regola che non scarta mai i cambiamenti in coda.

## Where in the code

lib/core/services/sync_service.dart: gestione dell'eliminazione remota di una nota e invio della coda; in coda la verifica sul cloud trova la nota assente e invia comunque il salvataggio.
