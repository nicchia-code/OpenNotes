---
column: done
technical: false
refs:
  - vault-file/Written/note.PERMANENTLY_DELETED
drift: imtfqodh
proposal: null
agent: false
created: 2026-10-17T13:41:35.375Z
finished: 2026-10-17T13:43:02.519Z
---
# Fix code to match the Model: Vault file: titles differing only by letter case share one file, and deleting one removes the other's copy

## What happens

Su macOS e Windows il file system non distingue maiuscole e minuscole: due note con titoli che differiscono solo per le lettere maiuscole scrivono lo stesso file del vault, e l'ultimo salvataggio sovrascrive il contenuto dell'altra. Quando una delle due viene eliminata definitivamente, il controllo che decide se il file è ancora usato confronta il testo del percorso e non trova l'altra nota, perché il suo percorso scritto differisce per le maiuscole. Il file viene quindi cancellato anche se l'altra nota lo ricorda ancora, e l'altra nota resta nel cestino o nell'elenco senza copia nel vault. Dovrebbe invece restare il file, con la copia dell'altra nota, come accade quando i titoli sono identici.

## What should happen

Il Model dice che il file si cancella solo se nessun'altra nota, anche nel cestino, risulta scritta nello stesso file, e che la nota che resta mantiene la sua copia; il Requirement dice la stessa cosa per la cancellazione definitiva. Su questi sistemi due percorsi che differiscono solo per maiuscole indicano lo stesso file, ma il Model non dice che cosa conta come stesso file: il caso non è coperto, e cambia i dati conservati nel vault perché una nota viva perde la sua copia.

## Chosen option

**Confronto dell'identità del file sul disco**

Prima di cancellare un file, per ogni altra nota che ricorda un percorso si verifica con il file system se punta allo stesso file (identità del file, non testo del percorso). Il file si cancella solo se nessuna nota lo condivide, e la copia rimasta si riscrive dal percorso che l'altra nota ricorda. Funziona su tutte le piattaforme e lascia invariato il comportamento su Linux. Costo: una verifica sul disco per ogni nota che ricorda un percorso nel cestino o nell'elenco, più codice di confronto da mantenere.

## Where in the code

lib/core/services/vault_service.dart (deleteNoteFileIfUnused); lib/core/services/database_service.dart (getNotesWrittenTo, query su file_path con confronto esatto)
