---
column: done
technical: false
refs:
  - editor-suggestions/Block menu
drift: nne3wanu
proposal: null
agent: false
created: 2026-10-12T11:27:34.810Z
finished: 2026-10-12T14:03:36.136Z
---
# Fix code to match the Model: Block menu stays open after the focus leaves its section

## What happens

Il menu rapido dei blocchi resta aperto sotto la sezione in cui è comparso anche quando il cursore passa in un'altra sezione e si scrive lì. Si chiude solo quando la sezione smette di cominciare con la barra, quando si sceglie una voce o quando cambia la nota.

## What should happen

Il Modello dice che i suggerimenti di tag si chiudono quando il focus lascia la sezione (LEAVE_NOTE_TEXT), ma per il menu rapido dei blocchi non dice nulla in questo caso. La transizione di digitazione (EDIT_NOTE_TEXT) può essere letta come riferita alla sola sezione che si sta modificando: in quel caso il menu dovrebbe chiudersi già alla digitazione in un'altra sezione. Il Modello non dice quale delle due letture vale.

## Chosen option

**Chiudere il menu quando il focus lascia la sezione**

Il menu si chiude appena il cursore esce dalla sezione, come i suggerimenti di tag. Il Modello del Block menu riceve una transizione LEAVE_NOTE_TEXT. Costo: per riaprire il menu si digita di nuovo la barra o si usa il pulsante della barra, quando sarà collegato.
