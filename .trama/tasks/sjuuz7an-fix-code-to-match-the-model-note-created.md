---
column: done
technical: false
refs:
  - note/Not yet created/user.CREATE_NOTE
drift: 41xbhham
proposal: null
agent: false
created: 2026-10-12T17:14:49.846Z
finished: 2026-10-12T17:18:30.527Z
---
# Fix code to match the Model: Note created in a folder view deleted in the cloud has no existing folder

## What happens

Quando una cartella viene eliminata da un altro dispositivo, la vista aperta su di essa resta su quella cartella, che non esiste più, e l'elenco è vuoto perché le sue note sono passate in Note. Se da quella vista si crea o si duplica una nota, la nota viene salvata nella cartella eliminata: non compare in nessuna cartella dell'elenco e resta visibile solo in Tutte le note.

## What should happen

Il Model dice che la vista resta sulla cartella eliminata, ma non dice dove va una nota creata o duplicata in quella vista. La regola di creazione mette la nota nella cartella selezionata, che però non esiste più. Una nota in una cartella inesistente non rispetta la regola per cui le note di una cartella eliminata passano in Note, e sparisce da ogni cartella.

## Chosen option

**Move the open view to All notes**

Quando la cartella viene eliminata da un altro dispositivo, la vista passa a Tutte le note, come già accade per l'eliminazione fatta sul dispositivo. Una nota creata o duplicata finisce quindi in una cartella che esiste. Costo: la vista cambia sotto gli occhi dell'utente; il Model della cartella e del navigatore va cambiato per il caso remoto, e l'arrivo dell'eliminazione dal cloud deve reimpostare la selezione.

## Where in the code

lib/core/state/notes_provider.dart (createNote e duplicateNote prendono la cartella dalla selezione senza verificarla); lib/core/services/sync_service.dart (handleRemoteFolderChange non reimposta la selezione, a differenza di deleteFolder).
