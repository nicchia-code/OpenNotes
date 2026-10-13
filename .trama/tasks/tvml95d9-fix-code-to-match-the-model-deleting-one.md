---
column: done
technical: false
refs:
  - vault-file/Written/note.PERMANENTLY_DELETED
drift: 3llf478c
proposal: null
agent: false
created: 2026-10-12T11:44:40.881Z
finished: 2026-10-12T11:46:08.814Z
---
# Fix code to match the Model: Deleting one of two notes that share a vault file removes the other note's copy

## What happens

Le note nuove nascono tutte con il titolo «Nuova nota», e più note con lo stesso titolo scrivono lo stesso file nel vault: l'ultimo salvataggio sovrascrive il precedente. Se una di queste note viene eliminata definitivamente, il file viene cancellato anche quando contiene la copia dell'altra nota. L'altra nota resta nell'elenco e risulta ancora scritta nel vault, ma non ha più il suo file finché non viene salvata di nuovo.

## What should happen

Il Model dice che l'eliminazione definitiva cancella il file della nota che ricorda dove l'ha scritto, e che una nota con lo stesso titolo di un'altra sovrascrive il file. Non dice però che cosa succede alla copia dell'altra nota quando una delle due viene eliminata: il caso non è coperto e cambia i dati conservati nel vault, perché una nota viva perde la sua copia.

## Chosen option

**Il file si cancella solo se nessun'altra nota lo usa**

Alla cancellazione definitiva il file viene rimosso solo se nessun'altra nota risulta scritta nello stesso file. La copia dell'altra nota resta nel vault e viene cancellata quando anche l'ultima nota che la usa viene eliminata. Non cambia il nome dei file e non perde dati di note vive. Costo: il Model della cancellazione va completato con questa condizione, e il file può restare nel vault a nome di una nota già eliminata.

## Where in the code

lib/core/state/notes_provider.dart (permanentlyDeleteNote, emptyTrash); lib/core/services/vault_service.dart (saveNote, deleteNoteFile)
