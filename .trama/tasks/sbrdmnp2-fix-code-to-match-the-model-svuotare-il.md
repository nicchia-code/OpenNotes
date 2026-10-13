---
column: done
technical: false
refs:
  - note/In trash/user.EMPTY_TRASH
  - note-access/Protected
  - requirements/rules#note-access
drift: lhps2n5p
proposal: null
agent: false
created: 2026-10-12T18:00:24.473Z
finished: 2026-10-12T18:03:16.833Z
---
# Fix code to match the Model: Svuotare il cestino elimina le note protette nascoste senza PIN

## What happens

Con una ricerca o un tag attivi nella vista Cestino, la barra mostra solo le note filtrate. Se una nota protetta non compare in quell'elenco, «Svuota» la elimina definitivamente senza chiedere il PIN, perché il controllo guarda solo le note mostrate.

## What should happen

Il Model dell'accesso alla nota dice che eliminare definitivamente una nota protetta chiede ogni volta il PIN. Il Model delle note dice che Svuota elimina tutte le note nel cestino, ma chiede il PIN solo se una delle note mostrate è protetta. Il Requirement dice che svuotare il cestino richiede il PIN quando tra le note mostrate ce n'è una protetta. Non dice cosa succede alle note protette nascoste dal filtro.

## Chosen option

**Chiedere il PIN se nel cestino c'è almeno una nota protetta, anche nascosta**

Il PIN serve per ogni nota protetta nel cestino, non solo per quelle mostrate. Il Model delle note e il Requirement cambiano da «mostrate» a «nel cestino». Costo: una lettura del cestino completo prima della conferma; nessuna nota protetta sparisce senza PIN.

## Where in the code

lib/ui/notes_list/notes_list_view.dart (_confirmEmptyTrash); lib/ui/mobile/mobile_notes_list_screen.dart (Svuota cestino); lib/core/state/notes_provider.dart (emptyTrash)
