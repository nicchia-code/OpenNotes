---
status: resolved
resolution: fix-code
refs:
  - vault-file/Written/note.PERMANENTLY_DELETED
proposal: null
task: pynfx28j
origin: null
critical: false
option: 1
note: null
resolvedBy: m16unv7j
created: 2026-10-12T11:20:27.565Z
---
# Vault file: a permanently deleted note keeps its file although the app remembers where it wrote it

## What happens

Quando una nota viene eliminata definitivamente, dal menu, dal cestino svuotato o per una cancellazione arrivata dal cloud, il file Markdown della nota resta nel vault. L'app salva però, a ogni scrittura, il percorso del file in cui ha scritto la nota e lo conserva nella nota; la cancellazione non lo usa mai e non rimuove nulla dal vault.

## What should happen

Il Modello dice che la cancellazione definitiva rimuove il file quando la nota ricorda dove l'ha scritto, e che oggi la nota non lo ricorda mai. Entrambe le affermazioni non reggono: il percorso è memorizzato. Il requisito sul nome del file dice invece che la posizione del file scritto non viene memorizzata, mentre il requisito dei dati prevede un percorso facoltativo nella nota. Modello e requisiti non sono coerenti tra loro e non posso stabilire da solo quale vale.

## Fix options

### Il file viene rimosso insieme alla nota

L'app usa il percorso già salvato per cancellare il file alla cancellazione definitiva, anche per quelle arrivate dal cloud e dal cambio account, come descritto nel Modello. Costo: il requisito sul nome va riscritto perché la posizione viene memorizzata; le copie lasciate dai cambi di titolo precedenti restano nel vault.

### Il file resta nel vault

La cancellazione definitiva non tocca il file, che resta come copia orfana. Il Modello va riscritto eliminando il ramo di rimozione, e il percorso memorizzato non serve più. Costo: il vault accumula le copie di tutte le note eliminate, e la rimozione introdotta in precedenza viene annullata.

## Where in the code

lib/core/state/notes_provider.dart (permanentlyDeleteNote, emptyTrash); lib/core/services/sync_service.dart (cancellazioni dal cloud, cambio account)
