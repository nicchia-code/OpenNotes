---
column: done
technical: false
refs:
  - mobile-navigation/Notes list
drift: null
proposal: null
agent: false
created: 2026-10-12T16:48:33.188Z
finished: 2026-10-12T17:09:38.820Z
---
# Fix code to match the Model: Notes list search field starts empty while the shared search still filters

## What happens

Sul telefono, aprendo una lista di note dalla schermata Cartelle mentre la ricerca è ancora attiva, il campo di ricerca compare vuoto, ma la lista è filtrata dalla ricerca precedente: vede solo le note che corrispondono a una ricerca che non si legge più. Il campo si svuota solo quando la ricerca viene azzerata dal codice, non quando la lista viene riaperta.

## What should happen

Il Model (mobile-navigation) dice che le schermate leggono e cambiano la stessa selezione corrente, e che la ricerca fa parte di questa selezione; la lista ha il campo di ricerca. Una lista riaperta deve quindi mostrare nel campo la ricerca che sta filtrando le note, così il campo e l'elenco restano coerenti.

## Where in the code

lib/ui/mobile/mobile_notes_list_screen.dart (campo di ricerca della lista, creato sempre vuoto; la ricerca sta nel NotesProvider)
