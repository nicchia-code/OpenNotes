---
column: done
technical: false
refs:
  - vault-file/Written/note.PERMANENTLY_DELETED
drift: ts8689s4
proposal: null
agent: false
created: 2026-10-12T11:27:34.815Z
finished: 2026-10-12T11:29:51.661Z
---
# Fix code to match the Model: Vault file: a permanently deleted note keeps its file although the app remembers where it wrote it

## What happens

Quando una nota viene eliminata definitivamente, dal menu, dal cestino svuotato o per una cancellazione arrivata dal cloud, il file Markdown della nota resta nel vault. L'app salva però, a ogni scrittura, il percorso del file in cui ha scritto la nota e lo conserva nella nota; la cancellazione non lo usa mai e non rimuove nulla dal vault.

## What should happen

Il Modello dice che la cancellazione definitiva rimuove il file quando la nota ricorda dove l'ha scritto, e che oggi la nota non lo ricorda mai. Entrambe le affermazioni non reggono: il percorso è memorizzato. Il requisito sul nome del file dice invece che la posizione del file scritto non viene memorizzata, mentre il requisito dei dati prevede un percorso facoltativo nella nota. Modello e requisiti non sono coerenti tra loro e non posso stabilire da solo quale vale.

## Chosen option

**Il file viene rimosso insieme alla nota**

L'app usa il percorso già salvato per cancellare il file alla cancellazione definitiva, anche per quelle arrivate dal cloud e dal cambio account, come descritto nel Modello. Costo: il requisito sul nome va riscritto perché la posizione viene memorizzata; le copie lasciate dai cambi di titolo precedenti restano nel vault.

## Where in the code

lib/core/state/notes_provider.dart (permanentlyDeleteNote, emptyTrash); lib/core/services/sync_service.dart (cancellazioni dal cloud, cambio account)
