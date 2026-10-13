---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#note-browser
proposal: null
task: pxvzqd75
origin: null
critical: false
option: 1
note: null
resolvedBy: i14darb0
created: 2026-10-12T18:46:26.427Z
---
# Tag count and tag filter disagree on hashtags written only in the text

## What happens

La barra laterale conta una nota sotto un tag anche quando quel tag compare solo come cancelletto nel testo della nota, ma selezionando il tag la nota non compare. Il numero accanto al tag non corrisponde alle note elencate: per esempio una nota che scrive un tag nel testo senza averlo tra i tag salvati è contata ma non mostrata.

## What should happen

Il Requirement dà due regole diverse: l'elenco dei tag conta i tag salvati uniti a quelli scritti nel testo, mentre la corrispondenza per il filtro usa solo i tag salvati. Due decisioni già prese sul punto vanno in direzioni opposte (una tiene solo i tag salvati, l'altra fa contare il filtro anche sui tag del testo), e nessuna è stata riportata nel Requirement né applicata al conteggio. Il conteggio e il filtro devono riferirsi alle stesse note.

## Fix options

### Contare solo i tag salvati

Il conteggio e il filtro usano entrambi solo i tag salvati con la nota, come deciso per la divergenza sul filtro. Numero e note elencate tornano a coincidere. Costo: un tag scritto nel testo conta solo dopo un nuovo salvataggio; le note arrivate dal cloud senza tag salvati non compaiono sotto i tag del loro testo finché non vengono salvate di nuovo. Il Requirement dell'elenco dei tag va riscritto.

### Cercare anche i tag nel testo

Il filtro riconosce un tag anche quando è scritto con il cancelletto nel testo della nota, come già fa il conteggio. Numero e note elencate coincidono senza un nuovo salvataggio. Costo: il filtro legge il testo di ogni nota a ogni selezione, con più lavoro su archivi grandi. Il tag resta intero, quindi un tag più lungo non corrisponde. Il Requirement di corrispondenza va riscritto.

### Lasciare com'è e dichiararlo

Nessun cambio di codice: il conteggio include i tag del testo e il filtro solo quelli salvati, come oggi scritto nel Requirement. Costo: il numero accanto a un tag può superare le note elencate sotto di esso, e l'utente lo legge come un errore. Il Requirement va completato per dire esplicitamente che i due numeri possono differire.

## Where in the code

lib/core/services/database_service.dart (getNotes per il filtro, getAllTags per il conteggio); lib/core/models/note_model.dart (storedTags, allTags)
