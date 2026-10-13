---
status: resolved
resolution: fix-code
refs:
  - note-access/Protected
proposal: null
task: o0cvjx6m
origin: null
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:23:07.900Z
---
# Model still says the empty-trash PIN check covers only shown notes

## What happens

Svuota il cestino chiede il PIN se tra tutte le note nel cestino c'è almeno una nota protetta, anche quando un filtro o una ricerca la nasconde. Così è stato deciso per il Task sbrdmnp2, chiuso. Il Model dice ancora che il PIN serve solo se tra le note mostrate nella vista Cestino ce n'è una protetta.

## What should happen

Il Model dell'accesso alla nota (stato Protected), il Model delle note (EMPTY_TRASH) e il Requirement dell'accesso dicono «tra le note mostrate». La scelta fatta con il Task sbrdmnp2 prevedeva di cambiarli in «nel cestino», ma il testo non è stato aggiornato: il Model non riflette più la decisione presa.

## Fix options

### Update the Model to the chosen rule (recommended)

Il Model dell'accesso, il Model delle note e il Requirement cambiano «tra le note mostrate» in «nel cestino», come deciso con il Task sbrdmnp2. Il comportamento del codice resta com'è. Costo: poche parole in tre punti del Model e del Requirement; nessun cambiamento per l'utente.

### Ask the PIN only for the notes shown

Svuota chiede il PIN solo se tra le note visibili con il filtro attuale ce n'è una protetta, come scrive il Model oggi. Costo: con un filtro o una ricerca attivi una nota protetta nascosta viene eliminata senza PIN, il caso che il Task sbrdmnp2 ha chiuso; il Task va riaperto.

## Where in the code

lib/core/state/notes_provider.dart (trashHasProtectedNote, emptyTrash); lib/ui/notes_list/notes_list_view.dart (_confirmEmptyTrash); lib/ui/mobile/mobile_notes_list_screen.dart (Svuota cestino)
