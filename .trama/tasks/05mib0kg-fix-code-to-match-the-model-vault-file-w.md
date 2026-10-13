---
column: done
technical: false
refs:
  - vault-file/Written/note.SAVED
  - vault-file/Written/note.PERMANENTLY_DELETED
drift: fgyuqip3
proposal: null
agent: false
created: 2026-10-12T17:14:49.835Z
finished: 2026-10-12T17:22:20.083Z
---
# Fix code to match the Model: Vault file write or removal failure is not in the Model outside content saves

## What happens

Se scrivere o cancellare il file nel vault fallisce durante un'azione sulla nota (creazione, duplicazione, fissaggio, protezione, spostamento, cestino, ripristino o eliminazione definitiva), l'errore non viene gestito: l'azione non si completa e l'utente non riceve alcun avviso. Nel cestino il database cambia prima del file: se la scrittura fallisce, la nota risulta nel cestino ma il suo file non è aggiornato e la sincronizzazione non è avvisata. Nell'eliminazione definitiva il file viene tolto per primo: se la rimozione fallisce, la nota resta nel cestino e nessuna cancellazione viene accodata per il cloud.

## What should happen

Il Model dice che ogni salvataggio scrive il file e poi avvisa la sincronizzazione, ma non dice cosa succede se la scrittura o la cancellazione del file non riesce: se l'azione va annullata, se va ritentata, se l'utente va avvisato e se il database deve restare coerente con il file. Per il solo salvataggio del testo della nota esiste già una regola (ritentare e avvisare), che non copre le altre azioni che scrivono il file.

## Chosen option

**Annullare l'azione e avvisare**

Se il file non si scrive o non si cancella, il database resta come prima: l'azione non avviene, l'utente vede un avviso che dice che la nota non è stata salvata e la sincronizzazione non parte. Nel cestino il file va scritto prima del database, come negli altri salvataggi, così che un errore non lasci la nota a metà. Costo: l'utente ripete l'azione nei rari casi di errore del disco; serve un punto unico per mostrare l'avviso.

## Where in the code

lib/core/state/notes_provider.dart (togglePin, toggleLock, moveToTrash, restoreFromTrash, moveNoteToFolder, duplicateNote, createNote, _purgeNotes); lib/core/services/vault_service.dart (saveNote, deleteNoteFileIfUnused). Nessuna cattura dell'errore nei chiamanti dell'interfaccia (note_actions, mobile_notes_list_screen).
