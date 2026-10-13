---
column: done
technical: true
refs:
  - requirements/rules#note-content-save
drift: qrssvivp
proposal: null
agent: false
created: 2026-10-12T08:09:28.383Z
finished: 2026-10-12T08:14:24.728Z
---
# Fix code to match the Requirements: Tags with accented letters are cut short

## What happens

Un tag scritto con lettere accentate viene tagliato alla prima lettera accentata: «#perché» diventa il tag «perch», «#città» diventa «citt». Il tag troncato compare nell'elenco dei tag e nel filtro, e la parola intera non viene riconosciuta come tag.

## What should happen

La Requirement del salvataggio dice che un tag è fatto di lettere latine, cifre, «_» e «-». Le Requirement di note e di organizzazione dicono lettere ASCII. Le due formulazioni si contraddicono: con «latine» le lettere accentate fanno parte del tag, con «ASCII» il tag si ferma prima. Il codice segue la seconda.

## Chosen option

**Accettare le lettere accentate**

Un tag contiene anche le lettere accentate: «#perché» resta «perché» e si filtra con quello. Costo: le ricerche dei tag confrontano anche lettere accentate; le note già salvate con tag troncati cambiano solo quando vengono modificate; le Requirement di note e organizzazione vanno allineate.

## Where in the code

lib/core/models/note_model.dart (extractTagsFromContent e la regex dei tag; isOnlyTags)
