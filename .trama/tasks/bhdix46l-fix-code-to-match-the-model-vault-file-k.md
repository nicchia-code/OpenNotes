---
column: done
technical: false
refs:
  - vault-file/Written/note.PERMANENTLY_DELETED
  - realtime-channel.CLOUD_NOTE_REMOVED
drift: null
proposal: null
agent: false
created: 2026-10-12T11:38:28.913Z
finished: 2026-10-12T13:52:45.985Z
---
# Fix code to match the Model: Vault file kept when a queued edit of a cloud-deleted note is dropped

## Cosa fare

Quando una nota è stata eliminata nel cloud e sul dispositivo c'è ancora una modifica in coda per essa, la sincronizzazione rimuove la nota dal dispositivo senza cancellare il suo file nel vault. Il Model dice che la cancellazione per cancellazione avvenuta nel cloud (evento PERMANENTLY_DELETED della nota) rimuove la nota insieme al suo file, e che il file viene cancellato quando la nota ricorda dove è stata scritta: la transizione vault-file Written → Removed deve quindi scattare anche su questo ramo.

Nel codice: lib/core/services/sync_service.dart, passo 1 di syncNow (ramo delle note), dove la nota non più presente nel cloud viene rimossa con permanentlyDeleteNote senza chiamare deleteNoteFile sul percorso memorizzato della nota. Aggiungere la cancellazione del file con il percorso della nota locale, come fanno gli altri rami di cancellazione.
