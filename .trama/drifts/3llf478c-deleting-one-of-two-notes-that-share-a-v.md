---
status: resolved
resolution: fix-code
refs:
  - vault-file/Written/note.PERMANENTLY_DELETED
proposal: null
task: tvml95d9
origin: null
critical: false
option: 1
note: null
resolvedBy: 6dq6m1w3
created: 2026-10-12T11:38:45.413Z
---
# Deleting one of two notes that share a vault file removes the other note's copy

## What happens

Le note nuove nascono tutte con il titolo «Nuova nota», e più note con lo stesso titolo scrivono lo stesso file nel vault: l'ultimo salvataggio sovrascrive il precedente. Se una di queste note viene eliminata definitivamente, il file viene cancellato anche quando contiene la copia dell'altra nota. L'altra nota resta nell'elenco e risulta ancora scritta nel vault, ma non ha più il suo file finché non viene salvata di nuovo.

## What should happen

Il Model dice che l'eliminazione definitiva cancella il file della nota che ricorda dove l'ha scritto, e che una nota con lo stesso titolo di un'altra sovrascrive il file. Non dice però che cosa succede alla copia dell'altra nota quando una delle due viene eliminata: il caso non è coperto e cambia i dati conservati nel vault, perché una nota viva perde la sua copia.

## Fix options

### Il file si cancella solo se nessun'altra nota lo usa

Alla cancellazione definitiva il file viene rimosso solo se nessun'altra nota risulta scritta nello stesso file. La copia dell'altra nota resta nel vault e viene cancellata quando anche l'ultima nota che la usa viene eliminata. Non cambia il nome dei file e non perde dati di note vive. Costo: il Model della cancellazione va completato con questa condizione, e il file può restare nel vault a nome di una nota già eliminata.

### Il file si cancella sempre, e la copia dell'altra nota si ricrea al salvataggio

La cancellazione resta com'è oggi: il file della nota viene rimosso anche se contiene la copia di un'altra nota. L'altra nota ritrova il suo file solo al prossimo salvataggio. Costo: fino a quel salvataggio la nota non ha copia nel vault, e se non viene più modificata non la avrà mai; il Model va scritto di conseguenza.

### Ogni nota ha un file suo

Quando il nome è già usato da un'altra nota, la nota scrive un file con un nome diverso, per esempio con un numero in coda. Nessuna nota sovrascrive più il file di un'altra, e la cancellazione non tocca copie altrui. Costo: il nome del file non dipende più solo dal titolo, va cambiata la regola sul nome del file e il Model del salvataggio, che oggi prevede la sovrascrittura.

## Where in the code

lib/core/state/notes_provider.dart (permanentlyDeleteNote, emptyTrash); lib/core/services/vault_service.dart (saveNote, deleteNoteFile)
