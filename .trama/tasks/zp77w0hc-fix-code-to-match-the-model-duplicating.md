---
column: done
technical: false
refs:
  - note-browser/Browsing
  - requirements/rules#note-browser
drift: s2kd4dbl
proposal: null
agent: false
created: 2026-10-12T18:23:16.150Z
finished: 2026-10-12T18:25:10.824Z
---
# Fix code to match the Model: Duplicating a note also clears the search text, the Model says only creation does

## What happens

Quando l'utente duplica una nota mentre la ricerca è attiva, il testo di ricerca viene svuotato, così la copia compare nell'elenco e viene aperta nell'editor. Il comportamento è già nel sistema, ma non è scritto da nessuna parte nel Model.

## What should happen

Il Model della vista Browsing dice che il testo di ricerca resta attivo quando si cambia vista e si svuota solo quando si crea una nota. Il Requirement sulla ricerca dice la stessa cosa: solo la creazione svuota il testo. La duplicazione non è nominata.

## Chosen option

**Il Model e il Requirement includono anche la duplicazione**

Il Model e il Requirement dicono che anche duplicare una nota svuota il testo di ricerca, come la creazione. La copia è sempre visibile e aperta, come oggi nel codice. Costo: la ricerca attiva si perde a ogni duplicazione, e il Requirement va aggiornato insieme al Model.

## Where in the code

lib/core/state/notes_provider.dart, duplicateNote: azzera il testo di ricerca prima di ricaricare l'elenco.
