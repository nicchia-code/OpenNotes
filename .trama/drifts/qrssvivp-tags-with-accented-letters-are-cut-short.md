---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#note-content-save
proposal: null
task: 4sbvt9ct
origin: null
critical: false
option: 1
note: null
resolvedBy: p136jufl
created: 2026-10-12T08:02:11.384Z
---
# Tags with accented letters are cut short

## What happens

Un tag scritto con lettere accentate viene tagliato alla prima lettera accentata: «#perché» diventa il tag «perch», «#città» diventa «citt». Il tag troncato compare nell'elenco dei tag e nel filtro, e la parola intera non viene riconosciuta come tag.

## What should happen

La Requirement del salvataggio dice che un tag è fatto di lettere latine, cifre, «_» e «-». Le Requirement di note e di organizzazione dicono lettere ASCII. Le due formulazioni si contraddicono: con «latine» le lettere accentate fanno parte del tag, con «ASCII» il tag si ferma prima. Il codice segue la seconda.

## Fix options

### Accettare le lettere accentate

Un tag contiene anche le lettere accentate: «#perché» resta «perché» e si filtra con quello. Costo: le ricerche dei tag confrontano anche lettere accentate; le note già salvate con tag troncati cambiano solo quando vengono modificate; le Requirement di note e organizzazione vanno allineate.

### Solo lettere ASCII

Il tag si ferma alla prima lettera accentata, come ora. Costo: «#perché» diventa «perch» senza alcun avviso, una scelta poco leggibile per chi scrive in italiano; la Requirement del salvataggio va riscritta con «ASCII».

### Niente tag con lettere accentate

Una parola con lettere accentate non è un tag: «#perché» resta testo normale e non compare nei tag né nel filtro. Costo: il tag non compare mai, e l'utente non vede il motivo; la Requirement va scritta di conseguenza in tutte e tre le Area.

## Where in the code

lib/core/models/note_model.dart (extractTagsFromContent e la regex dei tag; isOnlyTags)
