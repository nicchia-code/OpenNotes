---
status: resolved
resolution: proposal
refs:
  - note-access/Protected
proposal: null
task: null
origin: null
previous: iduazsdz
critical: false
option: null
note: null
resolvedBy: xqdml6er
created: 2026-10-17T11:33:24.719Z
---
# Model still says the empty-trash PIN check covers only shown notes after the fix

## What happens

Svuotare il cestino chiede il PIN se nel cestino c'è almeno una nota protetta, anche quando la nota è nascosta dal filtro o dalla ricerca attivi. Il Model dell'accesso dice ancora che il PIN serve solo tra le note mostrate.

## What should happen

Il Drift iduazsdz ha chiuso la questione con la correzione del Model a «nel cestino», come deciso con il Task sbrdmnp2; il Model dell'accesso e il Requirement dicono ancora «tra le note mostrate».

## Fix options

### Update the Model to the chosen rule

Il Model dell'accesso, il Model delle note e il Requirement cambiano «tra le note mostrate» in «nel cestino», come deciso con il Task sbrdmnp2. Il comportamento del codice resta com'è. Costo: poche parole in tre punti del Model e del Requirement; nessun cambiamento per l'utente.

### Ask the PIN only for the notes shown

Svuotare chiede il PIN solo se tra le note visibili con il filtro attuale ce n'è una protetta, come scrive il Model oggi. Costo: con un filtro o una ricerca attivi una nota protetta nascosta viene eliminata senza PIN, il caso che il Task sbrdmnp2 ha chiuso.

## Where in the code

lib/core/state/notes_provider.dart, trashHasProtectedNote: controlla tutto il cestino
