---
status: resolved
resolution: fix-code
refs:
  - note-access/Locked
proposal: null
task: qu7a8thg
origin: null
previous: kwg75myp
critical: false
option: 1
note: null
resolvedBy: xqdml6er
created: 2026-10-17T11:33:17.194Z
---
# Search still matches the hidden text of protected notes after the fix

## What happens

La ricerca testuale trova le parole anche nel testo di una nota protetta ancora bloccata: la nota compare nell'elenco con il titolo e l'avviso, quindi la presenza di una parola nel testo emerge senza PIN. Il Task 2vuslq45 è chiuso come fatto, ma il comportamento è rimasto.

## What should happen

Il contenuto di una nota protetta resta nascosto finché l'utente non inserisce il PIN. Il Model dell'accesso non dice se la ricerca può usare il testo; la scelta approvata con il Drift kwg75myp è che, finché la nota non è sbloccata, la ricerca usi solo titolo e tag.

## Fix options

### Search only title and tags until unlock

Per una nota protetta non sbloccata nella sessione la ricerca usa solo titolo e tag; il testo entra nella ricerca dopo lo sblocco. Nessuna parola nascosta emerge senza PIN. Costo: poche righe nella query dell'elenco; con la nota bloccata, una parola del solo corpo non la trova.

### Never search protected text

Il testo di una nota protetta non entra mai nella ricerca, nemmeno dopo lo sblocco. Più semplice da spiegare, ma la ricerca nel corpo delle note sbloccate non funziona per le note protette.

## Where in the code

lib/core/services/database_service.dart, getNotes: il filtro searchQuery confronta anche il contenuto di ogni nota, protetta o no
