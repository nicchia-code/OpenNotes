---
status: resolved
resolution: fix-code
refs:
  - note/Not yet created/user.CREATE_NOTE
proposal: null
task: sjuuz7an
origin: null
critical: false
option: 1
note: null
resolvedBy: psazi867
created: 2026-10-12T17:02:07.122Z
---
# Note created in a folder view deleted in the cloud has no existing folder

## What happens

Quando una cartella viene eliminata da un altro dispositivo, la vista aperta su di essa resta su quella cartella, che non esiste più, e l'elenco è vuoto perché le sue note sono passate in Note. Se da quella vista si crea o si duplica una nota, la nota viene salvata nella cartella eliminata: non compare in nessuna cartella dell'elenco e resta visibile solo in Tutte le note.

## What should happen

Il Model dice che la vista resta sulla cartella eliminata, ma non dice dove va una nota creata o duplicata in quella vista. La regola di creazione mette la nota nella cartella selezionata, che però non esiste più. Una nota in una cartella inesistente non rispetta la regola per cui le note di una cartella eliminata passano in Note, e sparisce da ogni cartella.

## Fix options

### Move the open view to All notes

Quando la cartella viene eliminata da un altro dispositivo, la vista passa a Tutte le note, come già accade per l'eliminazione fatta sul dispositivo. Una nota creata o duplicata finisce quindi in una cartella che esiste. Costo: la vista cambia sotto gli occhi dell'utente; il Model della cartella e del navigatore va cambiato per il caso remoto, e l'arrivo dell'eliminazione dal cloud deve reimpostare la selezione.

### Create in Notes when the folder is gone

La vista resta sulla cartella eliminata, come dice il Model, ma una nota creata o duplicata lì va nella cartella Note. La nota compare così in una cartella che esiste, ma non nella vista che l'utente sta guardando, che resta vuota. Costo: una regola in più sia nella creazione sia nella copia, e una frase del Model che la descriva.

## Where in the code

lib/core/state/notes_provider.dart (createNote e duplicateNote prendono la cartella dalla selezione senza verificarla); lib/core/services/sync_service.dart (handleRemoteFolderChange non reimposta la selezione, a differenza di deleteFolder).
