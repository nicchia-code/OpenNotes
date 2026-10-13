# Vault File

La copia Markdown di una nota nel vault locale: un file con i metadati della nota in un'intestazione seguiti dal contenuto della nota così come è salvato. Ogni nota ne produce una a ogni salvataggio sul dispositivo; il vault non viene mai riletto dall'app.

## States

### Absent (initial)
Il file non esiste ancora nel vault.
- `note.SAVED` → Written: scrive il file nella cartella principale del vault con un nome ricavato dal titolo attuale della nota; se esiste già un file con lo stesso nome, per esempio di un'altra nota con lo stesso titolo, lo sovrascrive.

### Written
Il file contiene la versione della nota dell'ultimo salvataggio; anche le note spostate nel cestino restano nel vault, marcate come eliminate.
- `note.SAVED` → Written: se il nome ricavato dal titolo attuale coincide con quello del file; riscrive il file con lo stato attuale della nota, che sia una modifica del testo, il fissaggio, la protezione, lo spostamento, il cestino, il ripristino o una modifica arrivata dal cloud.
- `note.SAVED` → Orphaned: se il titolo è cambiato e ne deriva un nome diverso; la nota viene scritta in un nuovo file, che parte da Absent, e questo file resta nel vault non più aggiornato.
- `note.PERMANENTLY_DELETED` → Removed: solo se la nota ricorda dove è stata scritta la sua copia; cancella il file.
- `note.PERMANENTLY_DELETED` → Orphaned: se la nota non ricorda dove è stata scritta la sua copia, cosa che oggi accade sempre; il file resta nel vault.

### Removed (final)
Il file è stato cancellato dal vault.

### Orphaned (final)
Il file resta nel vault ma non corrisponde più a nessuna nota o a nessuna versione futura della nota.
