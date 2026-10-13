---
status: resolved
resolution: fix-code
refs:
  - vault-file/Written/note.SAVED
  - vault-file/Written/note.PERMANENTLY_DELETED
proposal: null
task: 05mib0kg
origin: null
critical: false
option: 1
note: null
resolvedBy: psazi867
created: 2026-10-12T16:48:24.490Z
---
# Vault file write or removal failure is not in the Model outside content saves

## What happens

Se scrivere o cancellare il file nel vault fallisce durante un'azione sulla nota (creazione, duplicazione, fissaggio, protezione, spostamento, cestino, ripristino o eliminazione definitiva), l'errore non viene gestito: l'azione non si completa e l'utente non riceve alcun avviso. Nel cestino il database cambia prima del file: se la scrittura fallisce, la nota risulta nel cestino ma il suo file non è aggiornato e la sincronizzazione non è avvisata. Nell'eliminazione definitiva il file viene tolto per primo: se la rimozione fallisce, la nota resta nel cestino e nessuna cancellazione viene accodata per il cloud.

## What should happen

Il Model dice che ogni salvataggio scrive il file e poi avvisa la sincronizzazione, ma non dice cosa succede se la scrittura o la cancellazione del file non riesce: se l'azione va annullata, se va ritentata, se l'utente va avvisato e se il database deve restare coerente con il file. Per il solo salvataggio del testo della nota esiste già una regola (ritentare e avvisare), che non copre le altre azioni che scrivono il file.

## Fix options

### Annullare l'azione e avvisare

Se il file non si scrive o non si cancella, il database resta come prima: l'azione non avviene, l'utente vede un avviso che dice che la nota non è stata salvata e la sincronizzazione non parte. Nel cestino il file va scritto prima del database, come negli altri salvataggi, così che un errore non lasci la nota a metà. Costo: l'utente ripete l'azione nei rari casi di errore del disco; serve un punto unico per mostrare l'avviso.

### Ritentare come per il testo

Si applica anche alle altre azioni la regola già scritta per il testo: la modifica resta in attesa, si riprova alla consegna successiva o al ritorno in primo piano, e l'avviso compare finché la scrittura non riesce. Costo: serve una coda di scritture per tutte le azioni, più complessa da mantenere; per un tempo la nota può apparire cambiata mentre il file del vault è ancora quello vecchio.

### Database come fonte, file come copia

Il database resta la fonte: se il file non si scrive o non si cancella, l'azione si completa nell'app, l'errore viene solo registrato e il file viene riallineato al salvataggio successivo della nota. Costo: il vault può restare indietro senza che l'utente se ne accorga, e nell'eliminazione definitiva la nota sparisce dall'app mentre il file resta nel vault.

## Where in the code

lib/core/state/notes_provider.dart (togglePin, toggleLock, moveToTrash, restoreFromTrash, moveNoteToFolder, duplicateNote, createNote, _purgeNotes); lib/core/services/vault_service.dart (saveNote, deleteNoteFileIfUnused). Nessuna cattura dell'errore nei chiamanti dell'interfaccia (note_actions, mobile_notes_list_screen).
