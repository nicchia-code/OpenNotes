---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Block menu
  - requirements/rules#editor-suggestions
proposal: null
task: txfz5icy
origin: null
critical: false
option: 1
note: null
resolvedBy: 32w3ze0y
created: 2026-10-12T18:16:17.291Z
---
# Block menu stays under another section after its section is merged or removed

## What happens

Il menu rapido dei blocchi resta aperto anche quando la sua sezione di testo sparisce. Succede se il menu è aperto su una sezione vuota, o con il cursore a inizio sezione, e si preme Cancella: la sezione viene unita a quella sopra e tolta. Il menu allora compare sotto la sezione che segue, che non ha il focus, e scegliere una voce cambia quella sezione. Lo stesso accade se si toglie un'immagine che sta sopra la sezione con il menu aperto.

## What should happen

Il menu deve stare sotto la sezione che ha il focus e chiudersi quando il focus lascia quella sezione. Una sezione tolta dal documento porta via il suo menu: il menu non deve passare a un'altra sezione.

## Fix options

### Chiudere il menu quando la sua sezione sparisce

Quando una sezione viene unita o tolta, il menu aperto su di lei si chiude. Il testo che resta nella sezione sopra riceve il focus come oggi, senza menu. È la regola già scritta nel Requisito, applicata anche al caso in cui la sezione non esiste più. Costo: piccolo, nessun comportamento visibile nuovo; l'utente deve digitare di nuovo la barra per aprire il menu.

### Riaprire il menu sulla sezione che riceve il cursore

Quando la sezione con il menu sparisce, il menu si riapre sotto la sezione che riceve il cursore, se ha un testo che comincia con una barra o se è stato aperto dal pulsante. Costo: più logica da mantenere e più casi da provare, e il menu compare dove l'utente non l'ha chiamato dopo un Cancella.

## Where in the code

lib/ui/editor/notion_document_editor.dart (_removeBlockAt, _mergeBlockWithPrevious, il menu legato all'indice della sezione in _buildBlockWidget e _slashMenuBlockIndex)
