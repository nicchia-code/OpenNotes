---
column: done
technical: false
refs:
  - note-content-save
drift: null
proposal: null
agent: false
created: 2026-10-12T14:48:12.528Z
finished: 2026-10-12T16:37:26.079Z
---
# Fix code to match the Requirements: Note title cut at 60 code units, the Requirement counts characters

## What happens

Il titolo di una nota viene tagliato a 60 unità di codice invece che a 60 caratteri. Un titolo con emoji o altri caratteri fuori dal piano base viene quindi accorciato prima: con 60 emoji il titolo ne mostra solo 30, e il taglio può cadere a metà di un carattere, lasciando un carattere spezzato.

## What should happen

Il Requirement dice che il titolo si taglia a 60 caratteri: un carattere fuori dal piano base conta come uno. Il taglio avviene per caratteri interi, senza spezzarne nessuno.

## Where in the code

lib/core/models/note_model.dart, _clipTitle: il controllo della lunghezza e il taglio usano length e substring sulle unità di codice. Il Task 3k6ct68q ha corretto lo stesso problema nel nome del file del vault, ma non nel titolo.
