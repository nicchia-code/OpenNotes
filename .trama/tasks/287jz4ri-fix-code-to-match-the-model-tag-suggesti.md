---
column: done
technical: false
refs:
  - editor-suggestions/Tag suggestions
drift: tovqdnsn
proposal: null
agent: false
created: 2026-10-13T06:42:09.796Z
finished: 2026-10-13T06:46:32.744Z
---
# Fix code to match the Model: Tag suggestions stay under another section after its section is merged or removed

## What happens

Il menu dei tag resta aperto anche quando la sua sezione di testo sparisce. Succede se il menu è aperto e il cursore è a inizio sezione, per esempio dopo averlo spostato con le frecce senza cambiare il testo, e si preme Cancella: la sezione viene unita a quella sopra e tolta. Il menu allora compare sotto la sezione che segue, che non ha il focus. Se si tocca quella sezione, il tag scelto o Invio non lavorano più nel punto giusto: Invio non va a capo finché il menu non si chiude.

## What should happen

Il menu dei tag deve stare sotto la sezione che ha il focus e chiudersi quando il focus lascia la sezione in cui si scriveva il tag. Una sezione tolta dal documento porta via il suo menu: il menu non deve passare a un'altra sezione. Lo stesso vale per il menu dei blocchi, che già si chiude in questo caso.

## Chosen option

**Chiudere il menu dei tag quando la sua sezione sparisce**

Quando una sezione viene unita a quella sopra o tolta, il menu dei tag aperto su di lei si chiude, come già fa il menu dei blocchi. Il testo unito resta nella sezione sopra senza menu, e per avere i suggerimenti l'utente digita di nuovo il tag. Costo: piccolo, nessun comportamento nuovo visibile.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _removeBlockAt e _mergeBlockWithPrevious non azzerano il riferimento al menu dei tag, che è un indice di sezione e dopo la rimozione indica la sezione seguente
