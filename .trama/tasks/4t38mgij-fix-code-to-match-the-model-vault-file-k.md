---
column: done
technical: false
refs:
  - vault-file/Written
  - folder/User folder/user.DELETE_FOLDER
drift: w5pmekbh
proposal: null
agent: false
created: 2026-10-17T18:38:45.617Z
finished: 2026-10-17T18:42:33.880Z
---
# Fix code to match the Model: Vault file keeps the old folder of notes moved by a folder deletion

## What happens

Quando l'utente elimina una cartella, le sue note, anche quelle nel cestino, passano nella cartella Note nell'app e nei dati locali, ma la loro copia Markdown nel vault resta con la cartella di prima. Lo stesso accade quando la cartella viene eliminata altrove e le sue note passano a Note senza entrare nella coda: anche lì la copia nel vault non viene riscritta. La copia resta com'è finché la nota non viene salvata di nuovo.

## What should happen

Il Model dice che ogni volta che una nota viene scritta sul dispositivo, nel database e come file nel vault, la sua copia nel vault viene riscritta (evento **note.SAVED**). Il Model della cartella dice che le note spostate nella cartella Note passano lì senza cambiare la data di modifica e vengono messe in coda come salvataggi, quindi la copia deve riportare la cartella nuova. Il Requirement dell'intestazione include la cartella della nota. Il Model del file nel vault non dice se questo spostamento riscrive la copia: il caso non è coperto.

## Chosen option

**Riscrivere la copia di ogni nota spostata**

Quando la cartella viene eliminata qui, la copia Markdown di ogni nota spostata viene riscritta nella stessa operazione, prima di cancellare la cartella. Quando l'eliminazione arriva dal cloud, le copie vengono riscritte durante la sincronizzazione. Il vault e l'app dicono sempre la stessa cartella. Costi: una scrittura in più per nota spostata, e una cartella con molte note richiede più tempo; una scrittura fallita nella sincronizzazione va ritentata al giro successivo, come le altre annotazioni del registro.

## Where in the code

lib/core/state/notes_provider.dart (deleteFolder); lib/core/services/database_service.dart (deleteFolder, che sposta le note anche per le cartelle eliminate dal cloud); lib/core/services/sync_service.dart (rimozione di una cartella ricevuta dal cloud, e cartelle locali rimosse dal controllo completo)
