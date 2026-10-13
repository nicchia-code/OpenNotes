---
column: done
technical: true
refs:
  - requirements/rules#note-browser
drift: ko7r1uek
proposal: null
agent: false
created: 2026-10-12T18:49:15.949Z
finished: 2026-10-12T18:51:01.531Z
---
# Fix code to match the Requirements: Tag count and tag filter disagree on hashtags written only in the text

## What happens

La barra laterale conta una nota sotto un tag anche quando quel tag compare solo come cancelletto nel testo della nota, ma selezionando il tag la nota non compare. Il numero accanto al tag non corrisponde alle note elencate: per esempio una nota che scrive un tag nel testo senza averlo tra i tag salvati è contata ma non mostrata.

## What should happen

Il Requirement dà due regole diverse: l'elenco dei tag conta i tag salvati uniti a quelli scritti nel testo, mentre la corrispondenza per il filtro usa solo i tag salvati. Due decisioni già prese sul punto vanno in direzioni opposte (una tiene solo i tag salvati, l'altra fa contare il filtro anche sui tag del testo), e nessuna è stata riportata nel Requirement né applicata al conteggio. Il conteggio e il filtro devono riferirsi alle stesse note.

## Chosen option

**Contare solo i tag salvati**

Il conteggio e il filtro usano entrambi solo i tag salvati con la nota, come deciso per la divergenza sul filtro. Numero e note elencate tornano a coincidere. Costo: un tag scritto nel testo conta solo dopo un nuovo salvataggio; le note arrivate dal cloud senza tag salvati non compaiono sotto i tag del loro testo finché non vengono salvate di nuovo. Il Requirement dell'elenco dei tag va riscritto.

## Where in the code

lib/core/services/database_service.dart (getNotes per il filtro, getAllTags per il conteggio); lib/core/models/note_model.dart (storedTags, allTags)
