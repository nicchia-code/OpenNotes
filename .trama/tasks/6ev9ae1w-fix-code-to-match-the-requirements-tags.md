---
column: done
technical: true
refs:
  - requirements/rules#note-browser
drift: nrki8shi
proposal: null
agent: false
created: 2026-10-17T08:41:40.194Z
finished: 2026-10-17T08:42:39.679Z
---
# Fix code to match the Requirements: Tags written in a new note's text are still not saved at creation (recurring)

## What happens

Le note create con un testo iniziale che contiene #tag, come le due note di benvenuto (#note #opennotes e #todo #produttività), salvano solo i tag del filtro attivo, cioè nessuno se nessun tag è selezionato. Così l'elenco dei tag, il conteggio e il filtro non vedono i tag scritti nel testo finché la nota non viene salvata di nuovo. La correzione data come risolta non è nel codice.

## What should happen

Alla creazione una nota deve salvare anche i #tag presenti nel testo iniziale, come avviene a ogni salvataggio del contenuto. Così ogni tag che compare nel testo di una nota è tra i suoi tag salvati, e l'elenco dei tag e il filtro coincidono, come stabilito dal Drift chiuso con questo stesso problema.

## Chosen option

**Salvare i tag del testo alla creazione**

Alla creazione di una nota i #tag trovati nel testo iniziale si salvano insieme a quelli del filtro attivo, come a ogni salvataggio. Le note di benvenuto ottengono i loro tag e l'elenco, il conteggio e il filtro tornano coerenti. Le note già create senza tag restano così finché non vengono salvate di nuovo.

## Where in the code

lib/core/state/notes_provider.dart (createNote); lib/core/services/database_service.dart (getAllTags, getNotes); lib/main.dart (_createWelcomeNotes)
