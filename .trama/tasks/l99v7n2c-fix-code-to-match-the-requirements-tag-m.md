---
column: done
technical: true
refs:
  - requirements/rules#note-browser
drift: qoh15b4z
proposal: null
agent: false
created: 2026-10-12T17:14:49.863Z
finished: 2026-10-12T17:16:28.659Z
---
# Fix code to match the Requirements: Tag matching in the Requirements uses saved tags only, the tag list uses hashtags in the text too

## What happens

Il filtro per tag e il conteggio dei tag della barra laterale usano i tag di una nota uniti ai **#tag scritti nel suo testo**: una nota compare sotto un tag anche se quel tag sta solo nel testo. Per esempio le note di benvenuto, create con #note nel testo e senza tag salvati, compaiono sotto #note, e l'elenco dei tag conta la stessa nota.

## What should happen

La regola di corrispondenza dei tag dice che una nota corrisponde a un tag solo se i suoi **tag memorizzati** lo contengono, quindi un tag scritto solo nel testo non dovrebbe far comparire la nota. La stessa regola, nella parte sull'elenco dei tag, unisce però i tag memorizzati a quelli del testo, e il Model dice che i tag di una nota sono quelli salvati uniti a quelli scritti nel testo. Filtro ed elenco non possono seguire entrambe le regole: la corrispondenza va allineata.

## Chosen option

**Corrispondenza sui tag della nota uniti al testo**

Il filtro usa la stessa regola dell'elenco: tag salvati più i **#tag** scritti nel testo. Filtro, conteggi ed elenco restano d'accordo, e le note di benvenuto o arrivate dal cloud compaiono sotto i tag del loro testo anche senza un nuovo salvataggio. Il codice resta com'è; la regola di corrispondenza nel Requirement va riscritta. Costo: un tag scritto nel testo conta anche se non è tra quelli salvati.

## Where in the code

lib/core/services/database_service.dart (getNotes, getAllTags); lib/core/models/note_model.dart (allTags)
