---
status: resolved
resolution: fix-code
refs:
  - note/In trash/user.DELETE_NOTE_PERMANENTLY
  - requirements/rules#note/In trash
proposal: null
task: rtzyskeq
origin: null
critical: false
option: 1
note: null
resolvedBy: yv0225l5
created: 2026-10-12T12:09:43.578Z
---
# Permanent deletion removes the file last, while the Requirement puts the file first

## What happens

Eliminando definitivamente una nota, singola o svuotando il cestino, il dispositivo accoda prima la cancellazione per il cloud, poi elimina la nota dal database locale e solo alla fine rimuove il file dall'archivio Markdown, se nessun'altra nota lo usa. Il risultato finale è lo stesso, ma l'ordine dei passaggi è diverso.

## What should happen

Il Requirement del cestino dice che l'eliminazione definitiva avviene nell'ordine: prima il file dall'archivio Markdown, poi la cancellazione accodata per il cloud, infine la nota dal database locale. Il Model della nota descrive lo stesso ordine. Oggi il controllo che il file non sia usato da altre note legge il database, quindi il file viene tolto dopo la nota; con l'ordine scritto il controllo dovrebbe escludere la nota stessa.

## Fix options

### Rispettare l'ordine scritto

Il controllo sul file condiviso esclude la nota che si elimina; poi il file viene rimosso, la cancellazione viene accodata per il cloud e la nota tolta dal database. Il comportamento visibile non cambia. La sequenza va scritta in un solo punto, usato sia dall'eliminazione singola sia dallo svuotamento del cestino. Costa una piccola modifica al controllo sul database.

### Adottare l'ordine attuale nei documenti

Il Requirement del cestino e il Model della nota dicono che il file viene rimosso per ultimo, perché il controllo sui file condivisi legge il database. Il codice non cambia. Costa una modifica approvata del Requirement e del Model, perché l'ordine scritto non verrebbe più seguito.

## Where in the code

lib/core/state/notes_provider.dart (permanentlyDeleteNote, emptyTrash, _deleteFileIfUnused)
