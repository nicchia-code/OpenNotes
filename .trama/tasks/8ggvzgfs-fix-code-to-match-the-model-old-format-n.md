---
column: done
technical: false
refs:
  - text-line/Checklist item
  - requirements/rules#text-line
drift: ooydwa2p
proposal: null
agent: false
created: 2026-10-12T07:38:53.822Z
finished: 2026-10-12T07:53:56.058Z
---
# Fix code to match the Model: Old-format notes lose the indent of checklist items

## What happens

Aprendo una nota nel formato Markdown precedente (non JSON), una voce di checklist rientrata, come «  ○ voce» o «  - [ ] voce», torna a livello zero: il rientro sparisce e la voce diventa principale. Le voci puntate rientrate restano invece al loro livello.

## What should happen

Il Model dice che il rientro è di due spazi per livello e che le righe caricate da una nota partono nel tipo che si ricava dal contenuto: una voce di checklist rientrata deve restare di un livello più in là, come le voci puntate già restano.

## Chosen option

**Conservare il rientro anche nelle checklist**

Il caricamento del formato precedente tiene gli spazi davanti alle voci di checklist, come già fa per le voci puntate. Le note salvate in JSON non cambiano, perché già conservano il rientro. Costo: poche righe nel caricamento, da provare con una nota con voci di checklist annidate.

## Where in the code

lib/ui/editor/notion_document_editor.dart, _parseContentToBlocks (ramo del testo nel formato precedente, voci di checklist)
