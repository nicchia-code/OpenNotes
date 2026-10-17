---
status: resolved
resolution: fix-code
refs:
  - sync-run/Waiting to retry
  - requirements/rules#sync-run
proposal: null
task: fbs6n3np
origin: null
critical: false
option: 1
note: null
resolvedBy: tqf85in9
created: 2026-10-17T17:21:31.398Z
---
# Cloud errors answered by the database are not sorted into their categories

## What happens

Quando il cloud risponde con un errore alle richieste al database (un guasto del servizio, un limite di richieste, un tempo di attesa scaduto o una sessione scaduta), il giro fallisce ma l'app lo classifica come **errore imprevisto**: nella sincronizzazione compare "Errore imprevisto" invece di "Il cloud non risponde" o "Accesso scaduto: accedi di nuovo". Il difetto riguarda tutti i giri, perché letture e scritture di note e cartelle passano dalle stesse richieste al database.

## What should happen

Secondo i Requirements la categoria dipende dalla risposta del cloud: **5xx, 408 e 429** sono "cloud non disponibile", mostrato come "Il cloud non risponde"; **401** è "sessione scaduta", mostrato come "Accesso scaduto: accedi di nuovo"; ogni altro errore è "imprevisto". Questo vale per ogni richiesta al cloud, anche per quelle al database, non solo per quelle allo spazio di archiviazione degli allegati.

## Fix options

### Read the status of database answers

La classificazione legge il codice di stato della risposta anche per gli errori del database: 5xx, 408 e 429 diventano guasto del cloud, 401 diventa sessione scaduta, il resto resta imprevisto. Gli errori già riconosciuti non cambiano. Costo: un controllo in più sul tipo di errore, da coprire con un test sulle risposte del database.

### Classify failures where the run catches them

Il giro converte la risposta del cloud nella categoria già nel punto in cui riceve l'errore, insieme al tempo massimo di ogni richiesta, così ogni fallimento passa dallo stesso percorso. Costo: la logica di classificazione si sposta dal servizio di sincronizzazione alla gestione delle richieste, e va riverificata per ogni tipo di errore.

## Where in the code

lib/core/services/sync_service.dart: `syncErrorCategoryOf` riconosce gli errori dello spazio di archiviazione per codice di stato ma non gli errori del database (`PostgrestException`), che portano il codice di stato HTTP come `code`; la categoria finisce in `_runOnce`.
