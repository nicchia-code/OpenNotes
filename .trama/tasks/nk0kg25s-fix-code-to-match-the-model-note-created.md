---
column: done
technical: false
refs:
  - note-browser/Folder
drift: w5wxuj2f
proposal: null
agent: false
created: 2026-10-17T13:41:35.336Z
finished: 2026-10-17T13:42:50.846Z
---
# Fix code to match the Model: Note created in a folder view kept after a cloud deletion lands in a folder that no longer exists

## What happens

Quando una cartella viene eliminata da un altro dispositivo, la vista resta su di essa e l'elenco è vuoto, come vuole il Model. Se da quella vista si crea o si duplica una nota, la nota viene salvata con l'identificativo della cartella eliminata: compare nella vista aperta e in Tutte le note, ma in nessuna cartella della barra laterale. Il titolo della finestra intanto ripiega su «Tutte le note», mentre l'elenco mostra le note della cartella eliminata.

## What should happen

Il Model dice che la vista resta sulla cartella eliminata e che la nota nasce nella cartella selezionata; non dice dove finisce una nota creata quando quella cartella non esiste più. Il Requirement sulle cartelle non impone alcun vincolo tra nota e cartella, quindi la nota resterebbe in una cartella che non esiste. Con la vista che resta, la regola non è realizzabile senza decidere dove va la nota: è la stessa differenza della Drift 41xbhham, la cui soluzione (spostare la vista) è stata annullata dal Model attuale.

## Chosen option

**Create in Notes when the open folder is gone**

La creazione e la copia da una vista su una cartella eliminata usano la cartella Note, come per le note ricevute dal cloud; la vista resta vuota finché l'utente non cambia vista. Costo: la nota nuova non compare nella vista aperta, e la regola «nella cartella selezionata» va letta come «cartella esistente».

## Where in the code

lib/core/state/notes_provider.dart: createNote e duplicateNote usano _selectedFolderId senza verificare che la cartella esista; refreshFolders non cambia la selezione quando la cartella scompare. lib/ui/shell/mac_title_bar.dart: _getFolderTitle ripiega su 'Tutte le note' se la cartella non esiste.
