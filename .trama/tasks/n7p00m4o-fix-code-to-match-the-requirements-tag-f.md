---
column: done
technical: true
refs:
  - requirements/rules#note-browser
drift: st13ems5
proposal: null
agent: false
created: 2026-10-12T14:20:57.142Z
finished: 2026-10-12T14:22:50.322Z
---
# Fix code to match the Requirements: Tag filter matches saved tags only, not hashtags in the text

## What happens

Il filtro per tag considera solo i tag salvati con la nota. Una nota che nel testo scrive un tag con il cancelletto, ma non lo ha tra i tag salvati, non compare quando si seleziona quel tag. Il conteggio nella barra laterale, invece, la include già: così il numero di note non corrisponde a quelle elencate.

## What should happen

Una nota deve comparire sotto un tag se i suoi tag salvati lo contengono oppure se il suo testo contiene quel tag scritto con il cancelletto. Il filtro e il conteggio devono riferirsi alle stesse note, e un tag più lungo (per esempio «lavorobis» per «lavoro») non deve comparire.

## Chosen option

**Usare solo i tag salvati, ovunque**

Il filtro e l'elenco dei tag contano soltanto i tag salvati con la nota, e il testo con il cancelletto non conta finché la nota non viene salvata di nuovo. Filtro e conteggi restano sempre d'accordo. Costo: le note arrivate dal cloud con un elenco di tag non aggiornato non compaiono sotto un tag che hanno solo nel testo, finché non vengono modificate. Il Requirement va riscritto di conseguenza.

## Where in the code

lib/core/services/database_service.dart, getNotes (condizione sui tag); lib/core/services/database_service.dart, getAllTags (conteggio); test/tags_test.dart, test « tag filter uses only saved tags, not hashtags left in content ».
