---
status: resolved
resolution: proposal
refs:
  - pending-change/Set aside
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: awa4vyj9
created: 2026-10-17T14:12:55.529Z
---
# Set-aside change returns to the queue on save, the Model does not say so

## What happens

Quando l'utente salva di nuovo una nota la cui modifica è stata messa da parte dopo tre rifiuti, la modifica torna in coda al suo posto, senza più essere messa da parte, e viene inviata di nuovo. Lo stesso accade se la nota viene eliminata definitivamente: l'eliminazione prende il posto della modifica messa da parte e torna in coda.

## What should happen

Il Model dice che lo stato **Messa da parte** si lascia solo con le azioni dell'utente, Riprova e Usa la versione del cloud, e non descrive né il salvataggio né l'eliminazione definitiva di una nota messa da parte. Il Requirement delle regole di sincronizzazione dice invece che un nuovo salvataggio aggiorna la modifica messa da parte, che non lo è più, e che un'eliminazione definitiva la sostituisce allo stesso modo. Il Model e il Requirement non si accordano; il codice segue il Requirement.

## Where in the code

lib/core/services/database_service.dart: queueSyncAction (il salvataggio o l'eliminazione azzera il contrassegno di messa da parte)
