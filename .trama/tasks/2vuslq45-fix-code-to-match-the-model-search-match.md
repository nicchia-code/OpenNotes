---
column: done
technical: false
refs:
  - note-access/Locked
drift: kwg75myp
proposal: null
agent: false
created: 2026-10-12T14:57:05.730Z
finished: 2026-10-12T14:59:27.322Z
---
# Fix code to match the Model: Search matches hidden text of protected notes

## What happens

La ricerca testuale considera anche il testo di una nota protetta ancora bloccata. Digitando una parola che compare solo nel testo nascosto, la nota compare nell'elenco con il suo titolo e l'avviso «Questa nota è protetta», quindi l'utente capisce che il testo contiene quella parola, senza aver inserito il PIN.

## What should happen

Il Model dice che il contenuto di una nota protetta è nascosto finché l'utente non inserisce il PIN, e che nell'elenco restano visibili solo titolo, data, tag e lucchetto. Non dice se la ricerca può usare il testo nascosto. Se lo usa, un'informazione del contenuto emerge senza PIN: la scelta va decisa dallo sviluppatore.

## Chosen option

**Search hidden text only after unlock**

Per una nota protetta non sbloccata in questa sessione la ricerca usa solo titolo e tag; il testo entra nella ricerca dopo lo sblocco. Nessuna parola nascosta emerge senza PIN. Raccomandata.

## Where in the code

lib/core/services/database_service.dart getNotes (filtro searchQuery su title e content); lib/core/state/notes_provider.dart refreshNotes
