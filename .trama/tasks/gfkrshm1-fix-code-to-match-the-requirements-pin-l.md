---
column: done
technical: false
refs:
  - master-pin/Not set/user.LOCK_NOTE
  - requirements/rules#master-pin
drift: null
proposal: null
agent: false
created: 2026-10-12T15:05:14.945Z
finished: 2026-10-12T16:26:59.887Z
---
# Fix code to match the Requirements: PIN length counted in code units, the Requirement counts characters

Il PIN principale viene accettato o rifiutato contando le unità interne del testo: un carattere composto da più unità (per esempio un'emoji) conta due, mentre la regola chiede almeno quattro caratteri. Quando il lavoro è finito, un PIN di quattro caratteri è accettato anche se contiene caratteri non ASCII, e un PIN di tre caratteri è rifiutato con il messaggio «Il PIN deve avere almeno 4 cifre.», contati dopo aver tolto gli spazi iniziali e finali; il controllo sulla conferma e l'impronta restano invariati.
