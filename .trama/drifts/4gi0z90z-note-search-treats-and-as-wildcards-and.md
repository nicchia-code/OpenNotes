---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#note-browser
  - note-browser/All notes/user.CHANGE_SEARCH_QUERY
proposal: null
task: 4eriknn3
origin: null
critical: false
option: 1
note: null
resolvedBy: p136jufl
created: 2026-10-12T08:01:38.899Z
---
# Note search treats _ and % as wildcards and misses accented capitals

## What happens

Cercando un testo, la lista mostra anche le note che hanno un'altra parola al posto di un carattere: cercando `a_b` compare anche una nota con `axb`, perché il trattino basso e il segno di percentuale vengono trattati come caratteri jolly. Inoltre le lettere accentate maiuscole non vengono abbassate: cercando `è` non si trova una nota che contiene `È`.

## What should happen

La ricerca cerca il testo così come è stato digitato, come sottostringa, senza distinzione di maiuscole e minuscole, nel titolo e nel contenuto. Un carattere come `_` o `%` deve essere cercato come carattere normale, e una lettera maiuscola accentata deve essere trovata anche digitando la sua versione minuscola.

## Fix options

### Confrontare il testo in modo letterale

I caratteri `%` e `_` diventano normali e le maiuscole, anche accentate, vengono abbassate prima del confronto. La ricerca rispetta il requisito in tutti i casi. Costo: il filtro gira sulle note caricate invece che nel database, quindi è più lento su archivi molto grandi.

### Proteggere solo i caratteri jolly

I caratteri `%` e `_` vengono resi normali, e il filtro resta nel database: il cambiamento è piccolo e veloce. Costo: le lettere accentate maiuscole continuano a non essere trovate con la minuscola, quindi il requisito resta in parte non rispettato.

## Where in the code

lib/core/services/database_service.dart, lettura delle note (getNotes), condizione della ricerca testuale sul titolo e sul contenuto.
