---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Tag suggestions
proposal: null
task: 287jz4ri
origin: null
critical: false
option: 1
note: null
resolvedBy: nztyyq3m
created: 2026-10-13T06:35:30.584Z
---
# Tag suggestions stay under another section after its section is merged or removed

## What happens

Il menu dei tag resta aperto anche quando la sua sezione di testo sparisce. Succede se il menu è aperto e il cursore è a inizio sezione, per esempio dopo averlo spostato con le frecce senza cambiare il testo, e si preme Cancella: la sezione viene unita a quella sopra e tolta. Il menu allora compare sotto la sezione che segue, che non ha il focus. Se si tocca quella sezione, il tag scelto o Invio non lavorano più nel punto giusto: Invio non va a capo finché il menu non si chiude.

## What should happen

Il menu dei tag deve stare sotto la sezione che ha il focus e chiudersi quando il focus lascia la sezione in cui si scriveva il tag. Una sezione tolta dal documento porta via il suo menu: il menu non deve passare a un'altra sezione. Lo stesso vale per il menu dei blocchi, che già si chiude in questo caso.

## Fix options

### Chiudere il menu dei tag quando la sua sezione sparisce

Quando una sezione viene unita a quella sopra o tolta, il menu dei tag aperto su di lei si chiude, come già fa il menu dei blocchi. Il testo unito resta nella sezione sopra senza menu, e per avere i suggerimenti l'utente digita di nuovo il tag. Costo: piccolo, nessun comportamento nuovo visibile.

### Chiudere ogni menu di suggerimenti a ogni cambio di sezioni

Ogni volta che il documento perde o unisce una sezione, tutti i menu di tag e blocchi aperti si chiudono, anche se erano su un'altra sezione. È una regola unica e semplice da provare, ma chiude il menu anche in casi in cui il cursore resta nella sezione giusta. Costo: piccolo, qualche chiusura in più dopo un'unione.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _removeBlockAt e _mergeBlockWithPrevious non azzerano il riferimento al menu dei tag, che è un indice di sezione e dopo la rimozione indica la sezione seguente
