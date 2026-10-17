---
status: resolved
resolution: proposal
refs:
  - note-content-save/Waiting
  - note/Not yet created/user.DUPLICATE_NOTE
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: gdnc8czu
created: 2026-10-17T17:50:46.798Z
---
# Duplicate writes the waiting note content first, the Model has no such exit

## What happens

Se l'utente duplica una nota mentre una sua modifica aspetta ancora di essere scritta, la modifica viene scritta subito e poi la copia nasce con l'ultimo testo visto sullo schermo. La duplicazione è quindi trattata come i comandi che scrivono prima la modifica in attesa, ma il Model non la elenca tra questi.

## What should happen

Il Model **non dice nulla** su cosa accade alla modifica in attesa quando l'utente duplica la nota. Per fissare, proteggere, spostare o mettere nel cestino la nota dice invece che la modifica in attesa viene scritta prima del comando: la duplicazione non compare tra questi casi, quindi la copia non ha una regola precisa sul testo.

## Fix options

### Aggiungere la duplicazione tra i comandi che scrivono prima

Il Model prevede che, prima di creare la copia, la modifica in attesa venga scritta subito, come per fissare e spostare. Il comportamento del codice resta com'è: la copia contiene il testo visto sullo schermo. Costo: una voce in più nel Model, da aggiornare quando si aggiungono altri comandi che leggono il testo della nota.

### Copiare l'ultima versione salvata

La duplicazione non scrive la modifica in attesa: la copia nasce dal testo già salvato, e la modifica resta in attesa per l'originale. Costo: la copia può non contenere le ultime battute scritte nei 400 ms prima del comando, cioè parte del testo che l'utente vede sullo schermo. Il Model resta com'è.

## Where in the code

lib/ui/notes_list/note_actions.dart (ramo della duplicazione); lib/core/state/notes_provider.dart (flushPendingContent, duplicateNote)
