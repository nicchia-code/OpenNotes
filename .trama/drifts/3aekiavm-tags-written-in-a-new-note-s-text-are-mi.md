---
status: resolved
resolution: fix-code
refs:
  - note-browser/Browsing
  - requirements/data#note-browser
proposal: null
task: 9jvfrkn7
origin: null
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:33:22.967Z
---
# Tags written in a new note's text are missing from the tag list and filter

## What happens

Una nota creata con un testo iniziale che contiene dei #tag (per esempio le due note di benvenuto, con #note #opennotes e #todo #produttività) non salva quei tag. Così l'elenco dei tag non li mostra, la sezione TAG della barra laterale non compare al primo avvio e il filtro per quei tag non trova le note.

## What should happen

Il requisito dice che l'elenco dei tag conta anche i #tag presenti nel testo di ogni nota, e che una nota corrisponde a un tag quando lo ha tra i tag memorizzati. Le due regole coincidono solo se i tag memorizzati contengono quelli del testo, cosa che oggi non vale per le note create con testo iniziale.

## Fix options

### Salvare i tag del testo alla creazione

Quando una nota viene creata, i #tag trovati nel testo iniziale si salvano insieme a quelli della selezione, come già avviene a ogni salvataggio del testo. Le note di benvenuto avrebbero i loro tag, l'elenco e il filtro sarebbero coerenti. Costo: poco; le note create prima della modifica restano come sono.

### Salvare alla creazione e riallineare le note esistenti

Come la prima opzione, più un riallineamento che all'avvio ricalcola i tag memorizzati di ogni nota dal suo testo, così anche le note già salvate senza tag ottengono i loro. Costo: una lettura di tutte le note a ogni avvio, oppure un contrassegno da gestire per farlo una sola volta.

## Where in the code

lib/core/state/notes_provider.dart (createNote); lib/core/services/database_service.dart (getAllTags, getNotes); lib/main.dart (note di benvenuto)
