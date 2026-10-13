---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#note-browser
proposal: null
task: w0i5hhzc
origin: null
critical: false
option: 1
note: null
resolvedBy: ke2oiwmu
created: 2026-10-12T15:08:40.571Z
---
# Search ignores the content of protected notes, the Requirement counts it

## What happens

La ricerca dell'elenco confronta il testo cercato solo con il titolo e i tag delle note protette, finché non vengono sbloccate. Il contenuto nascosto non prende parte alla ricerca: una nota protetta compare solo se il testo cercato è nel suo titolo o tra i suoi tag.

## What should happen

Il requisito dice che la ricerca si combina con vista e tag e che una nota corrisponde se il titolo o il **contenuto grezzo** contiene il testo cercato, senza eccezioni per le note protette. La regola di protezione dice che il contenuto è nascosto nell'editor, non che sia escluso dalla ricerca.

## Fix options

### Keep protected text out of search

Le note protette restano trovabili solo per titolo e tag, come oggi, e il requisito di ricerca va riscritto per escludere il contenuto nascosto. Nessuna informazione sul testo protetto esce dal lucchetto. Costo: una parola presente solo nel corpo di una nota protetta non la fa comparire finché la nota non viene sbloccata.

### Search protected content as the Requirement says

La ricerca confronta anche il testo delle note protette, così l'elenco mostra una nota protetta quando la parola cercata sta solo nel suo corpo. Vanno cambiati il codice e il test attuale. Costo: chi guarda l'elenco, senza PIN, scopre che la nota contiene quella parola.

## Where in the code

lib/core/services/database_service.dart, getNotes (search filter); test/tags_test.dart, 'text search ignores content of locked notes until unlocked'
