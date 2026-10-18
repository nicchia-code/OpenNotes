---
status: resolved
resolution: proposal
refs:
  - requirements/rules#note-browser
proposal: null
task: null
origin: null
previous: pgtensg9
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T17:36:08.136Z
---
# Search rule still counts protected note text, the code and resolved Drift pgtensg9 exclude it

## What happens

Per una nota protetta ancora bloccata nella sessione, la ricerca confronta il testo cercato solo con titolo e tag: il contenuto nascosto non fa comparire la nota.

## What should happen

La regola di ricerca in requirements/rules#note-browser dice che una nota corrisponde se il titolo o il contenuto grezzo contengono il testo, senza eccezioni per le note protette. Il Drift pgtensg9 e la Proposal ke2oiwmu hanno deciso di escludere il contenuto nascosto e prevedevano di riscrivere il requisito, ma la Proposal non ha modificato alcun file e la regola è rimasta invariata.

## Fix options

### Rewrite the search rule to exclude hidden text

Riscrivere la regola di ricerca: per una nota protetta non sbloccata nella sessione la ricerca usa solo titolo e tag; il testo entra nella ricerca dopo lo sblocco. È la scelta già approvata con pgtensg9, ydm5fxwe e il Task w0i5hhzc, e richiede solo la modifica del requisito. Costo: una parola presente solo nel corpo di una nota protetta non la fa comparire finché la nota non viene sbloccata.

### Search protected content as the Requirement says

Mantenere la regola così com'è e far cercare anche il testo delle note protette bloccate: il codice in getNotes e il test 'text search ignores content of locked notes until unlock' vanno cambiati. Annulla la decisione di pgtensg9 e fa comparire una nota protetta quando la parola cercata sta solo nel suo corpo, rivelando la presenza di quella parola senza PIN.

## Where in the code

lib/core/services/database_service.dart, getNotes (filtro searchQuery, righe 235-250)
