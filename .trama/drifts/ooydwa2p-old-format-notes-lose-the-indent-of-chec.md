---
status: resolved
resolution: fix-code
refs:
  - text-line/Checklist item
  - requirements/rules#text-line
proposal: null
task: 8ggvzgfs
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:30:46.885Z
---
# Old-format notes lose the indent of checklist items

## What happens

Aprendo una nota nel formato Markdown precedente (non JSON), una voce di checklist rientrata, come «  ○ voce» o «  - [ ] voce», torna a livello zero: il rientro sparisce e la voce diventa principale. Le voci puntate rientrate restano invece al loro livello.

## What should happen

Il Model dice che il rientro è di due spazi per livello e che le righe caricate da una nota partono nel tipo che si ricava dal contenuto: una voce di checklist rientrata deve restare di un livello più in là, come le voci puntate già restano.

## Fix options

### Conservare il rientro anche nelle checklist

Il caricamento del formato precedente tiene gli spazi davanti alle voci di checklist, come già fa per le voci puntate. Le note salvate in JSON non cambiano, perché già conservano il rientro. Costo: poche righe nel caricamento, da provare con una nota con voci di checklist annidate.

### Appiattire le voci annidate al caricamento

Il caricamento accetta che le voci di checklist annidate diventino principali e lo dichiara nel Model. Costo: chi ha annidato le voci le vede appiattite alla prima riapertura. È la soluzione più semplice, ma il Model deve dire esplicitamente che il rientro non viene conservato.

## Where in the code

lib/ui/editor/notion_document_editor.dart, _parseContentToBlocks (ramo del testo nel formato precedente, voci di checklist)
