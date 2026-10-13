---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Block menu
proposal: null
task: 3cvm53vs
origin: null
critical: false
option: 1
note: null
resolvedBy: m16unv7j
created: 2026-10-12T11:20:08.644Z
---
# Block menu stays open after the focus leaves its section

## What happens

Il menu rapido dei blocchi resta aperto sotto la sezione in cui è comparso anche quando il cursore passa in un'altra sezione e si scrive lì. Si chiude solo quando la sezione smette di cominciare con la barra, quando si sceglie una voce o quando cambia la nota.

## What should happen

Il Modello dice che i suggerimenti di tag si chiudono quando il focus lascia la sezione (LEAVE_NOTE_TEXT), ma per il menu rapido dei blocchi non dice nulla in questo caso. La transizione di digitazione (EDIT_NOTE_TEXT) può essere letta come riferita alla sola sezione che si sta modificando: in quel caso il menu dovrebbe chiudersi già alla digitazione in un'altra sezione. Il Modello non dice quale delle due letture vale.

## Fix options

### Chiudere il menu quando il focus lascia la sezione

Il menu si chiude appena il cursore esce dalla sezione, come i suggerimenti di tag. Il Modello del Block menu riceve una transizione LEAVE_NOTE_TEXT. Costo: per riaprire il menu si digita di nuovo la barra o si usa il pulsante della barra, quando sarà collegato.

### Tenere il menu aperto sotto la sezione e dirlo nel Modello

Il comportamento attuale diventa la regola: il menu resta sotto la sezione finché questa comincia con la barra o finché non si sceglie una voce. Costo: il menu resta visibile sotto una sezione che l'utente ha lasciato, e il Modello va completato con questa transizione.

### Chiudere il menu alla digitazione in un'altra sezione

Il menu si chiude quando si scrive in un'altra sezione, ma resta aperto se il solo focus si sposta. Costo: un caso in più da descrivere nel Modello, e il comportamento dipende da cosa si scrive.
