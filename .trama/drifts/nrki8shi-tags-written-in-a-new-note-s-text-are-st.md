---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#note-browser
proposal: null
task: 6ev9ae1w
origin: null
previous: 3aekiavm
critical: false
option: 1
note: null
resolvedBy: 7qmreh1i
created: 2026-10-17T08:02:07.172Z
---
# Tags written in a new note's text are still not saved at creation (recurring)

## What happens

Le note create con un testo iniziale che contiene #tag, come le due note di benvenuto (#note #opennotes e #todo #produttività), salvano solo i tag del filtro attivo, cioè nessuno se nessun tag è selezionato. Così l'elenco dei tag, il conteggio e il filtro non vedono i tag scritti nel testo finché la nota non viene salvata di nuovo. La correzione data come risolta non è nel codice.

## What should happen

Alla creazione una nota deve salvare anche i #tag presenti nel testo iniziale, come avviene a ogni salvataggio del contenuto. Così ogni tag che compare nel testo di una nota è tra i suoi tag salvati, e l'elenco dei tag e il filtro coincidono, come stabilito dal Drift chiuso con questo stesso problema.

## Fix options

### Salvare i tag del testo alla creazione

Alla creazione di una nota i #tag trovati nel testo iniziale si salvano insieme a quelli del filtro attivo, come a ogni salvataggio. Le note di benvenuto ottengono i loro tag e l'elenco, il conteggio e il filtro tornano coerenti. Le note già create senza tag restano così finché non vengono salvate di nuovo.

### Salvare alla creazione e riallineare le note esistenti

Come la prima opzione, più un riallineamento all'avvio che ricalcola i tag salvati di ogni nota dal suo testo, così anche le note già create senza tag ottengono i loro. Costo: una lettura di tutte le note a ogni avvio, oppure un contrassegno che fa il riallineamento una sola volta.

## Where in the code

lib/core/state/notes_provider.dart (createNote); lib/core/services/database_service.dart (getAllTags, getNotes); lib/main.dart (_createWelcomeNotes)
