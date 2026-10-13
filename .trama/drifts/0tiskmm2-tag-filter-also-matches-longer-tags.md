---
status: resolved
resolution: fix-code
refs:
  - note/Active
  - requirements/rules#note
proposal: null
task: 39g2wjh1
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:29:01.517Z
---
# Tag filter also matches longer tags

## What happens

Quando si filtra per un tag, la lista mostra anche le note che nel testo contengono un tag più lungo che inizia allo stesso modo: con il tag **lavoro** compare una nota che ha solo il tag **lavorobis**.

## What should happen

Una nota appartiene solo ai tag che ha davvero: un tag è un `#` seguito da lettere, cifre, `_` o `-`. Il filtro deve mostrare solo le note che hanno il tag scelto, non quelle che contengono un tag diverso che inizia allo stesso modo.

## Fix options

### Filtrare solo sui tag salvati nella nota

Il filtro guarda soltanto i tag salvati con ogni nota, che vengono ricalcolati a ogni salvataggio del contenuto. Una nota compare sotto un tag solo se lo possiede davvero. Costo: una nota i cui tag salvati non sono aggiornati sparisce dal filtro finché non viene modificata di nuovo.

### Cercare nel testo solo tag completi

Il filtro continua a cercare anche nel testo, ma riconosce un tag solo se è intero e separato dal resto, con le stesse regole usate per i tag. Costo: la ricerca è più complessa da mantenere e un po' più lenta sugli elenchi lunghi.

## Where in the code

lib/core/services/database_service.dart, lettura delle note (getNotes): la condizione del filtro per tag confronta anche il testo della nota con il tag come sottostringa, senza verificarne i confini.
